# Fizzy OpenClaw Integration

AI Agent Orchestrator integration for Fizzy using OpenClaw.

## Architecture

Fizzy acts as the controller, sending enriched webhooks to fizzy-orchestrator with per-column agent context and native observability via file-tail relay.

## Components

- **`rails-plugin/`** - Fizzy Rails plugin (models, controllers, UI)
- **`relay/`** - File-tail relay for session observability
- **`docs/`** - Implementation specs and guides

## Quick Start

```bash
# Install the plugin
cd fizzy
bundle add ../fizzy-openclaw/rails-plugin

# Start the relay
cd ../fizzy-openclaw/relay
npm install
npm start

# Configure in Fizzy admin
# Board Settings → Agent
# Column Settings → Agent
```

## Documentation

- `docs/ARCHITECTURE.md` - System design
- `docs/IMPLEMENTATION.md` - Build guide
- `docs/API.md` - Relay API reference

## Status

🚧 Work in progress