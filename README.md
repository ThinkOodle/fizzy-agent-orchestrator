# Fizzy OpenClaw

AI agent integration for Fizzy boards via OpenClaw. Enables automatic agent spawning when cards move between columns, with per-board and per-column context configuration, and live activity display in the card detail panel.

## System Architecture

```
Card moves to column
    ↓
Column config checked (auto_spawn?)
    ↓
SessionSpawner POSTs to OpenClaw /hooks/fizzy
    { action: "column_changed", agent_context: {...} }
    ↓
OpenClaw spawns fizzy-orchestrator session
    (session key: "hook:fizzy:card-{card_number}")
    ↓
Relay watches ~/.openclaw/agents/fizzy-orchestrator/sessions/*.jsonl
    ↓
Fizzy card panel polls relay every 5s for live event log
```

## Components

### 1. Rails Plugin (`rails-plugin/`)

Mountable Rails engine with:
- **Models:** `BoardConfig`, `ColumnConfig`, `CardSession`
- **Service:** `SessionSpawner` — HTTP POST to OpenClaw webhook
- **CardExtension:** concern included into Fizzy's `Card` model
- **Controllers:** board config, column config, agent sessions (events proxy, start/stop)
- **Views:** edit forms, agent panel partial

### 2. Relay Server (`relay/`)

Node.js HTTP server that:
- Watches `~/.openclaw/agents/fizzy-orchestrator/sessions/*.jsonl`
- Indexes files by card number (looks for `hook:fizzy:card-{N}` in content)
- Serves `GET /events?card_number=123&after_seq=0`

### 3. JavaScript (`rails-plugin/app/javascript/`)

Stimulus controller `fizzy-openclaw--agent-panel` that:
- Polls `/openclaw/events` every 5 seconds while session is active
- Renders tool calls, assistant messages, errors
- Handles start/stop via AJAX

## Setup

### 1. Add to Fizzy Gemfile

```ruby
gem "fizzy-openclaw", path: "path/to/fizzy-openclaw/rails-plugin"
# or when published:
# gem "fizzy-openclaw", "~> 0.1"
```

### 2. Run migrations

```bash
bin/rails fizzy_openclaw:install:migrations
bin/rails db:migrate
```

### 3. Mount engine

```ruby
# config/routes.rb
mount FizzyOpenclaw::Engine => "/openclaw"
```

### 4. Configure credentials

```bash
bin/rails credentials:edit
```

```yaml
openclaw_hook_token: your-token-here
```

### 5. Import JavaScript

```javascript
// app/javascript/controllers/index.js
import AgentPanelController from "fizzy_openclaw/controllers/agent_panel_controller"
application.register("fizzy-openclaw-agent-panel", AgentPanelController)
```

### 6. Render the panel in card detail

```erb
<%# In your card detail view: %>
<%= render "fizzy_openclaw/agent_sessions/panel", card: @card %>
```

### 7. Add board/column config links

```erb
<%# In board settings view: %>
<%= link_to "Configure Agent", fizzy_openclaw.edit_board_agent_config_path(@board) %>

<%# In column settings view: %>
<%= link_to "Configure Agent", fizzy_openclaw.edit_column_agent_config_path(@column) %>
```

### 8. Start the relay

```bash
cd relay
npm install
npm start
# Runs on port 18795 by default
```

For production, use a systemd service or similar process manager.

## Environment Variables (Relay)

| Variable | Default | Description |
|----------|---------|-------------|
| `RELAY_PORT` | `18795` | HTTP port |
| `SESSIONS_DIR` | `~/.openclaw/agents/fizzy-orchestrator/sessions` | Path to watch |

## Relay API

### `GET /events`

| Param | Required | Description |
|-------|----------|-------------|
| `card_number` | yes | Card number (not ID) |
| `after_seq` | no | Return events with seq > this value (default: 0) |

Response:
```json
{
  "events": [
    { "seq": 1, "type": "tool_call", "tool": "read_file", "timestamp": "..." },
    { "seq": 2, "type": "assistant", "content": "I found the issue...", "timestamp": "..." }
  ],
  "has_more": false
}
```

### `GET /health`

Returns `{ "status": "ok", "sessions": N }`.

### `GET /sessions`

Debug endpoint — shows all indexed sessions and event counts.

## Testing

```bash
cd rails-plugin
bundle install
bundle exec rspec
```

## Session Key Format

OpenClaw session keys must include `hook:fizzy:card-{card_number}` somewhere in the session content (typically in the session metadata/first message) for the relay to index them correctly.
