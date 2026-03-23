import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    cardNumber: Number,
    lastSeq: { type: Number, default: 0 },
    status: { type: String, default: "idle" }
  }

  static targets = ["log", "status"]

  connect() {
    if (this.statusValue === "running" || this.statusValue === "pending") {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  start(event) {
    event.preventDefault()
    const form = event.target.closest("form")
    
    fetch(form.action, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      }
    })
    .then(r => r.json())
    .then(data => {
      if (data.status) {
        this.statusValue = data.status
        this.updateStatusDisplay()
        this.startPolling()
      } else {
        this.appendError(data.error || "Failed to start agent")
      }
    })
    .catch(e => this.appendError(e.message))
  }

  stop(event) {
    event.preventDefault()
    const form = event.target.closest("form")

    fetch(form.action, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      }
    })
    .then(r => r.json())
    .then(data => {
      this.statusValue = "stopped"
      this.updateStatusDisplay()
      this.stopPolling()
    })
    .catch(e => this.appendError(e.message))
  }

  startPolling() {
    if (this._pollTimer) return
    this._poll()
  }

  stopPolling() {
    if (this._pollTimer) {
      clearTimeout(this._pollTimer)
      this._pollTimer = null
    }
  }

  async _poll() {
    try {
      const url = `/openclaw/events?card_number=${this.cardNumberValue}&after_seq=${this.lastSeqValue}`
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })
      const data = await response.json()

      for (const event of (data.events || [])) {
        this.appendEvent(event)
        if (event.seq > this.lastSeqValue) {
          this.lastSeqValue = event.seq
        }
      }

      // Check if session is still active
      if (this.statusValue === "running" || this.statusValue === "pending") {
        this._pollTimer = setTimeout(() => this._poll(), 5000)
      }
    } catch (e) {
      console.error("[FizzyOpenclaw] Poll error:", e)
      this._pollTimer = setTimeout(() => this._poll(), 10000)
    }
  }

  appendEvent(event) {
    if (!this.hasLogTarget) return

    const div = document.createElement("div")
    div.className = `agent-event agent-event--${event.type || "unknown"}`

    const time = event.timestamp ? `<time class="agent-event-time">${new Date(event.timestamp).toLocaleTimeString()}</time>` : ""

    switch (event.type) {
      case "tool_call":
        div.innerHTML = `${time} <span class="tool-name">⚙ ${this._escapeHtml(event.tool || "")}</span>`
        if (event.args) {
          const args = document.createElement("pre")
          args.className = "tool-args"
          args.textContent = JSON.stringify(event.args, null, 2).substring(0, 300)
          div.appendChild(args)
        }
        break
      case "tool_result":
        div.innerHTML = `${time} <span class="tool-result">✓ ${this._escapeHtml(event.tool || "")}</span>`
        break
      case "assistant":
        div.innerHTML = `${time} <span class="assistant-text">${this._escapeHtml((event.content || "").substring(0, 300))}</span>`
        break
      case "error":
        div.innerHTML = `${time} <span class="agent-error">✗ ${this._escapeHtml(event.message || "error")}</span>`
        break
      default:
        div.textContent = `${event.type}: ${JSON.stringify(event).substring(0, 200)}`
    }

    this.logTarget.appendChild(div)
    this.logTarget.scrollTop = this.logTarget.scrollHeight
  }

  appendError(message) {
    if (!this.hasLogTarget) return
    const div = document.createElement("div")
    div.className = "agent-event agent-event--error"
    div.textContent = `Error: ${message}`
    this.logTarget.appendChild(div)
  }

  updateStatusDisplay() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = this.statusValue
      this.statusTarget.className = `agent-status agent-status--${this.statusValue}`
    }
  }

  _escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
