#!/usr/bin/env node
/**
 * Fizzy OpenClaw Relay
 *
 * Watches ~/.openclaw/agents/fizzy-orchestrator/sessions/*.jsonl
 * Indexes sessions by card number extracted from session content.
 * Serves events via HTTP for the Fizzy UI agent panel.
 *
 * GET /events?card_number=123&after_seq=0
 */

"use strict";

const fs = require("fs");
const path = require("path");
const http = require("http");
const readline = require("readline");
const os = require("os");

// Try to load chokidar, fall back to fs.watch
let chokidar;
try {
  chokidar = require("chokidar");
} catch (_) {
  chokidar = null;
}

const PORT = parseInt(process.env.RELAY_PORT || "18795", 10);
const SESSIONS_DIR = process.env.SESSIONS_DIR ||
  path.join(os.homedir(), ".openclaw", "agents", "fizzy-orchestrator", "sessions");

// Map: card_number (string) -> { filepath, events[], fileOffset }
const sessions = new Map();

// Map: filepath -> card_number (reverse index)
const fileIndex = new Map();

// Global sequence counter per card
const seqCounters = new Map();

function nextSeq(cardNumber) {
  const n = (seqCounters.get(cardNumber) || 0) + 1;
  seqCounters.set(cardNumber, n);
  return n;
}

/**
 * Extract card number from a line of JSONL content.
 * Looks for "hook:fizzy:card-{N}" anywhere in the line.
 */
function extractCardNumber(line) {
  const match = line.match(/hook:fizzy:card-(\d+)/);
  return match ? match[1] : null;
}

/**
 * Parse a JSONL line into an event object.
 */
function parseLine(line) {
  try {
    return JSON.parse(line);
  } catch (_) {
    return null;
  }
}

/**
 * Process a JSONL line and determine its event type.
 */
function lineToEvent(parsed) {
  if (!parsed) return null;

  // OpenClaw session JSONL schema varies — be flexible
  const type = parsed.type || parsed.event || "unknown";

  if (type === "tool_use" || type === "tool_call") {
    return {
      type: "tool_call",
      tool: parsed.name || parsed.tool || parsed.input?.name || "unknown",
      args: parsed.input || parsed.args || null,
      timestamp: parsed.timestamp || new Date().toISOString()
    };
  }

  if (type === "tool_result") {
    return {
      type: "tool_result",
      tool: parsed.tool_use_id || parsed.tool || "unknown",
      timestamp: parsed.timestamp || new Date().toISOString()
    };
  }

  if (type === "assistant" || type === "message") {
    const content = Array.isArray(parsed.content)
      ? parsed.content.map(c => c.text || "").join(" ")
      : (parsed.content || parsed.text || "");
    if (!content) return null;
    return {
      type: "assistant",
      content,
      timestamp: parsed.timestamp || new Date().toISOString()
    };
  }

  if (type === "error") {
    return {
      type: "error",
      message: parsed.message || parsed.error || "unknown error",
      timestamp: parsed.timestamp || new Date().toISOString()
    };
  }

  // Session metadata lines — look for card number here
  if (parsed.session_key || parsed.key) {
    return { type: "meta", raw: parsed };
  }

  return null;
}

/**
 * Read new lines from a file starting at offset.
 * Returns { lines, newOffset }.
 */
function readNewLines(filepath, startOffset) {
  const stat = fs.statSync(filepath);
  if (stat.size <= startOffset) return { lines: [], newOffset: startOffset };

  const buf = Buffer.alloc(stat.size - startOffset);
  const fd = fs.openSync(filepath, "r");
  fs.readSync(fd, buf, 0, buf.length, startOffset);
  fs.closeSync(fd);

  const text = buf.toString("utf8");
  const lines = text.split("\n").filter(l => l.trim().length > 0);
  return { lines, newOffset: stat.size };
}

/**
 * Process a file: scan for card number, then index events.
 */
function processFile(filepath) {
  let cardNumber = fileIndex.get(filepath);
  const entry = cardNumber ? sessions.get(cardNumber) : null;
  const startOffset = entry ? entry.fileOffset : 0;

  let { lines, newOffset } = readNewLines(filepath, startOffset);
  if (lines.length === 0) return;

  // If we don't know the card number yet, scan all lines for it
  if (!cardNumber) {
    for (const line of lines) {
      cardNumber = extractCardNumber(line);
      if (cardNumber) break;
    }
    if (!cardNumber) {
      // Can't determine card yet; scan full file from scratch next time
      return;
    }
    fileIndex.set(filepath, cardNumber);
  }

  // Initialize session entry if needed
  if (!sessions.has(cardNumber)) {
    sessions.set(cardNumber, { filepath, events: [], fileOffset: 0 });
  }
  const sess = sessions.get(cardNumber);
  sess.filepath = filepath;
  sess.fileOffset = newOffset;

  // Process lines into events
  for (const line of lines) {
    const parsed = parseLine(line);
    const event = lineToEvent(parsed);
    if (event && event.type !== "meta") {
      event.seq = nextSeq(cardNumber);
      sess.events.push(event);
    }
  }
}

/**
 * Initial scan of all existing files.
 */
function scanExistingFiles() {
  if (!fs.existsSync(SESSIONS_DIR)) {
    console.log(`[relay] Sessions dir not found: ${SESSIONS_DIR} — will watch when created`);
    return;
  }

  const files = fs.readdirSync(SESSIONS_DIR)
    .filter(f => f.endsWith(".jsonl"))
    .map(f => path.join(SESSIONS_DIR, f));

  for (const filepath of files) {
    try {
      processFile(filepath);
    } catch (e) {
      console.error(`[relay] Error scanning ${filepath}:`, e.message);
    }
  }

  console.log(`[relay] Scanned ${files.length} existing session files`);
}

/**
 * Set up file watching.
 */
function startWatching() {
  const watchPath = path.join(SESSIONS_DIR, "*.jsonl");

  if (chokidar) {
    const watcher = chokidar.watch(watchPath, {
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: { stabilityThreshold: 100 }
    });

    watcher
      .on("add", filepath => {
        console.log(`[relay] New session file: ${path.basename(filepath)}`);
        processFile(filepath);
      })
      .on("change", filepath => {
        processFile(filepath);
      });

    console.log(`[relay] Watching with chokidar: ${watchPath}`);
  } else {
    // Fallback: fs.watch on directory
    if (!fs.existsSync(SESSIONS_DIR)) {
      fs.mkdirSync(SESSIONS_DIR, { recursive: true });
    }

    fs.watch(SESSIONS_DIR, (eventType, filename) => {
      if (!filename || !filename.endsWith(".jsonl")) return;
      const filepath = path.join(SESSIONS_DIR, filename);
      if (fs.existsSync(filepath)) {
        processFile(filepath);
      }
    });

    console.log(`[relay] Watching with fs.watch: ${SESSIONS_DIR}`);
  }
}

/**
 * HTTP server.
 */
const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // Health check
  if (url.pathname === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", sessions: sessions.size }));
    return;
  }

  // GET /events?card_number=123&after_seq=0
  if (url.pathname === "/events" && req.method === "GET") {
    const cardNumber = url.searchParams.get("card_number");
    const afterSeq = parseInt(url.searchParams.get("after_seq") || "0", 10);

    if (!cardNumber) {
      res.writeHead(400, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "card_number required" }));
      return;
    }

    const sess = sessions.get(String(cardNumber));
    const allEvents = sess ? sess.events : [];
    const filtered = allEvents.filter(e => e.seq > afterSeq);

    // Re-scan file in case there's new data
    if (sess) {
      try { processFile(sess.filepath); } catch (_) {}
      // Get updated events after re-scan
      const updated = sessions.get(String(cardNumber));
      const fresh = updated ? updated.events.filter(e => e.seq > afterSeq) : filtered;

      res.writeHead(200, {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      });
      res.end(JSON.stringify({
        events: fresh,
        has_more: fresh.length >= 50
      }));
    } else {
      res.writeHead(200, {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      });
      res.end(JSON.stringify({ events: [], has_more: false }));
    }
    return;
  }

  // GET /sessions - debug endpoint
  if (url.pathname === "/sessions" && req.method === "GET") {
    const info = {};
    for (const [cardNum, sess] of sessions.entries()) {
      info[cardNum] = {
        filepath: path.basename(sess.filepath),
        event_count: sess.events.length,
        file_offset: sess.fileOffset
      };
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(info));
    return;
  }

  res.writeHead(404);
  res.end("Not found");
});

// Start up
scanExistingFiles();
startWatching();

server.listen(PORT, "127.0.0.1", () => {
  console.log(`[relay] Fizzy OpenClaw relay listening on http://127.0.0.1:${PORT}`);
  console.log(`[relay] Sessions dir: ${SESSIONS_DIR}`);
});

// Graceful shutdown
process.on("SIGTERM", () => { server.close(); process.exit(0); });
process.on("SIGINT", () => { server.close(); process.exit(0); });
