# Fizzy Agent Orchestrator

AI Agent Orchestrator for [Fizzy](https://fizzy.do). Enables per-board and per-column AI agent configuration with live session observability.

**Agent backend:** OpenClaw (first-party support). Designed to be extensible for other providers.

---

## How It Works

1. You configure a **system prompt** per board (project context) and per column (stage-specific instructions)
2. When a card enters a column with **auto-spawn enabled**, Fizzy fires a webhook to your OpenClaw instance with the full context
3. OpenClaw spawns an agent session and works on the card
4. The **relay** watches the session file and streams tool calls / output back to the Fizzy card UI in real time

```
Card moves to column
    ↓
Fizzy fires POST /hooks/fizzy (with agent_context)
    ↓
OpenClaw spawns fizzy-orchestrator session
    ↓
Relay watches JSONL session file
    ↓
Fizzy card UI polls relay every 5s → live log
```

---

## Installation

### 1. Add to Gemfile

```ruby
gem "fizzy_agent_orchestrator", github: "ThinkOodle/fizzy-agent-orchestrator", glob: "rails-plugin/*.gemspec"
```

### 2. Mount the engine

```ruby
# config/routes.rb
mount FizzyAgentOrchestrator::Engine => "/agent_orchestrator"
```

### 3. Add environment variables

```yaml
# .kamal/secrets (or your env management)
OPENCLAW_HOOK_TOKEN: <your-openclaw-hooks-token>
OPENCLAW_HOOK_URL: http://<your-openclaw-host>:18789/hooks/fizzy
OPENCLAW_RELAY_URL: http://<your-openclaw-host>:18795
```

### 4. Deploy

```bash
kamal deploy
```

Migrations run automatically on deploy via `db:prepare`. No manual DB steps needed.

---

## OpenClaw Setup

### 1. Enable webhook hooks in `~/.openclaw/openclaw.json`

```json5
{
  hooks: {
    enabled: true,
    token: "your-secret-token",
    allowedAgentIds: ["fizzy-orchestrator"],
    mappings: [
      {
        id: "fizzy",
        match: { path: "/fizzy" },
        action: "agent",
        agentId: "fizzy-orchestrator",
        deliver: false
      }
    ]
  }
}
```

### 2. Deploy the relay (on your OpenClaw host)

```bash
# Clone the repo and install relay
git clone https://github.com/ThinkOodle/fizzy-agent-orchestrator
cd fizzy-agent-orchestrator/relay
npm install

# Run as a service (systemd example)
# Or: node server.js &
```

**Relay env vars:**

| Variable | Default | Description |
|----------|---------|-------------|
| `RELAY_PORT` | `18795` | HTTP port |
| `SESSIONS_DIR` | `~/.openclaw/agents/fizzy-orchestrator/sessions` | JSONL sessions path |

### 3. Update fizzy-router.ts to handle agent context

Add to your `fizzy-router.ts` transform:

```typescript
if (action === 'column_changed') {
  const agentContext = event?.agent_context;
  if (!agentContext?.column_prompt) return null;

  const sessionKey = `hook:fizzy:card-${cardNumber}`;
  const contextPrefix = await buildFullContext('column_changed');
  const message = contextPrefix + '\n\n---\n\n' + agentContext.column_prompt;

  return { message, sessionKey, timeoutSeconds: (agentContext.timeout_minutes || 30) * 60 };
}
```

---

## Usage

1. Go to **Board Settings** → **Agent** tab
2. Set the board-level system prompt (project context, tech stack, conventions)
3. Go to **Column Settings** → **Agent** for any column
4. Set the column prompt and enable **Auto-spawn**
5. Move a card into that column — watch the agent panel in the card detail

---

## Architecture

- `rails-plugin/` — Rails Engine (models, controllers, Stimulus JS controller)
- `relay/` — Node.js file-tail relay for JSONL session observability

## License

MIT
