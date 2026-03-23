# Fizzy OpenClaw - Implementation Spec

## Overview
Build a Fizzy plugin that integrates with OpenClaw to enable AI agents on cards with per-column context configuration.

## System Flow

```
Card moves to column
    ↓
Fizzy checks column.agent_config
    ↓
If auto_spawn: POST /hooks/fizzy
    { action: "column_changed", agent_context: {...} }
    ↓
OpenClaw (fizzy-orchestrator) spawns session
    ↓
Relay watches JSONL file
    ↓
Fizzy UI polls relay every 5s for live log
```

## Components

### 1. Rails Plugin

**Models:**

```ruby
# app/models/fizzy_openclaw/board_config.rb
module FizzyOpenclaw
  class BoardConfig < ApplicationRecord
    belongs_to :board
    validates :system_prompt, presence: true
  end
end

# app/models/fizzy_openclaw/column_config.rb
module FizzyOpenclaw
  class ColumnConfig < ApplicationRecord
    belongs_to :column
    validates :system_prompt, presence: true, if: -> { auto_spawn? }
    
    def build_context(card)
      board_config = column.board.openclaw_board_config
      <<~CONTEXT
        #{board_config&.system_prompt}
        
        ---
        
        #{system_prompt}
        
        Card: #{card.title}
        Description: #{card.description}
      CONTEXT
    end
  end
end

# app/models/fizzy_openclaw/card_session.rb
module FizzyOpenclaw
  class CardSession < ApplicationRecord
    belongs_to :card
    enum status: { pending: 0, running: 1, completed: 2, failed: 3, stopped: 4 }
    
    def session_key
      "hook:fizzy:card-#{card_id}"
    end
  end
end
```

**Controllers:**

```ruby
# app/controllers/fizzy_openclaw/board_configs_controller.rb
module FizzyOpenclaw
  class BoardConfigsController < ApplicationController
    before_action :authorize_admin!
    
    def update
      @config = BoardConfig.find_or_initialize_by(board_id: params[:board_id])
      if @config.update(config_params)
        redirect_to board_path(@config.board), notice: "Updated"
      else
        render :edit
      end
    end
    
    private
    
    def config_params
      params.require(:board_config).permit(:system_prompt, :default_tools)
    end
  end
end
```

**Service:**

```ruby
# app/services/fizzy_openclaw/session_spawner.rb
module FizzyOpenclaw
  class SessionSpawner
    HOOK_URL = "http://localhost:18789/hooks/fizzy"
    
    def self.spawn(card, column_config)
      context = column_config.build_context(card)
      
      response = HTTParty.post(
        HOOK_URL,
        headers: { 
          'Authorization' => "Bearer #{hook_token}",
          'Content-Type' => 'application/json'
        },
        body: {
          action: 'column_changed',
          card: { id: card.id, number: card.number, title: card.title },
          column: { id: column_config.column.id, name: column_config.column.name },
          board: { id: column_config.column.board.id, name: column_config.column.board.name },
          agent_context: {
            board_prompt: column_config.column.board.openclaw_board_config&.system_prompt,
            column_prompt: column_config.system_prompt,
            timeout_minutes: column_config.timeout_minutes,
            allowed_tools: column_config.allowed_tools
          }
        }.to_json
      )
      
      if response.success?
        CardSession.create!(
          card: card,
          status: :running,
          started_at: Time.current
        )
      else
        Rails.logger.error "OpenClaw spawn failed: #{response.body}"
        nil
      end
    end
    
    def self.hook_token
      Rails.application.credentials.openclaw_hook_token
    end
  end
end
```

**Callback:**

```ruby
# app/models/fizzy_openclaw/card_extension.rb
module FizzyOpenclaw
  module CardExtension
    extend ActiveSupport::Concern
    
    included do
      has_one :openclaw_card_session, class_name: 'FizzyOpenclaw::CardSession', dependent: :destroy
      has_one :openclaw_column_config, through: :column, class_name: 'FizzyOpenclaw::ColumnConfig'
      
      after_update :spawn_openclaw_agent, if: :saved_change_to_column_id?
    end
    
    def spawn_openclaw_agent
      return unless openclaw_column_config&.auto_spawn?
      
      SessionSpawner.spawn(self, openclaw_column_config)
    end
  end
end
```

### 2. File-Tail Relay

**Location:** `relay/server.js`

**Features:**
- Watch `~/.openclaw/agents/fizzy-orchestrator/sessions/*.jsonl`
- Parse new lines as they arrive
- Index sessions by extracting `hook:fizzy:card-{N}` from content
- Serve HTTP: `GET /events?card_number=123&after_seq=0`

**Key Logic:**
```javascript
// Map: card_number -> { filepath, events[] }
const sessions = new Map();

// On file change, parse new lines
// Look for card number in session key pattern
// Store events with sequence numbers

// HTTP endpoint
app.get('/events', (req, res) => {
  const cardNum = req.query.card_number;
  const afterSeq = parseInt(req.query.after_seq || '0');
  
  const session = sessions.get(cardNum);
  if (!session) return res.json({ events: [], has_more: false });
  
  const events = session.events.filter(e => e.seq > afterSeq);
  res.json({ events, has_more: events.length >= 10 });
});
```

### 3. JavaScript UI

**Stimulus Controller:**

```javascript
// app/javascript/controllers/agent_panel_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { cardNumber: Number, lastSeq: Number }
  static targets = ["log", "status"]
  
  connect() {
    this.poll()
  }
  
  async poll() {
    try {
      const response = await fetch(
        `/openclaw/events?card_number=${this.cardNumberValue}&after_seq=${this.lastSeqValue}`
      )
      const data = await response.json()
      
      for (const event of data.events) {
        this.appendEvent(event)
        this.lastSeqValue = Math.max(this.lastSeqValue, event.seq)
      }
      
      if (this.statusTarget.textContent === "running") {
        setTimeout(() => this.poll(), 5000)
      }
    } catch (e) {
      console.error("Poll failed:", e)
      setTimeout(() => this.poll(), 10000)
    }
  }
  
  appendEvent(event) {
    const div = document.createElement("div")
    div.className = `agent-event agent-event--${event.type}`
    
    if (event.type === "tool_call") {
      div.innerHTML = `<code>${event.tool}</code> <time>${event.timestamp}</time>`
    } else if (event.type === "assistant") {
      div.textContent = event.content.substring(0, 200)
    }
    
    this.logTarget.appendChild(div)
  }
}
```

## Database Migrations

```ruby
# db/migrate/001_create_board_configs.rb
class CreateBoardConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :fizzy_openclaw_board_configs do |t|
      t.references :board, null: false, foreign_key: true
      t.text :system_prompt
      t.json :default_tools, default: ['file_read', 'file_write']
      t.timestamps
    end
    
    add_index :fizzy_openclaw_board_configs, :board_id, unique: true
  end
end

# db/migrate/002_create_column_configs.rb
class CreateColumnConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :fizzy_openclaw_column_configs do |t|
      t.references :column, null: false, foreign_key: true
      t.text :system_prompt
      t.boolean :auto_spawn, default: false
      t.integer :timeout_minutes, default: 30
      t.json :allowed_tools
      t.timestamps
    end
    
    add_index :fizzy_openclaw_column_configs, :column_id, unique: true
  end
end

# db/migrate/003_create_card_sessions.rb
class CreateCardSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :fizzy_openclaw_card_sessions do |t|
      t.references :card, null: false, foreign_key: true
      t.integer :status, default: 0
      t.integer :last_event_seq, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
    
    add_index :fizzy_openclaw_card_sessions, [:card_id, :status]
  end
end
```

## Routes

```ruby
# config/routes.rb
FizzyOpenclaw::Engine.routes.draw do
  resources :boards, only: [] do
    resource :agent_config, only: [:edit, :update], controller: 'board_configs'
  end
  
  resources :columns, only: [] do
    resource :agent_config, only: [:edit, :update], controller: 'column_configs'
  end
  
  resources :cards, only: [] do
    post :start_agent
    post :stop_agent
  end
  
  get '/events', to: 'agent_sessions#events'
end
```

## Installation

1. Add to Fizzy Gemfile
2. Run migrations
3. Configure credentials: `openclaw_hook_token`
4. Start relay service
5. Mount engine in routes

## Testing

```ruby
# spec/services/session_spawner_spec.rb
RSpec.describe SessionSpawner do
  let(:card) { create(:card) }
  let(:column_config) { create(:column_config, auto_spawn: true) }
  
  before do
    card.update!(column: column_config.column)
  end
  
  it "spawns session on column move" do
    expect(HTTParty).to receive(:post).with(
      /hooks\/fizzy/,
      hash_including(body: hash_including(:agent_context))
    ).and_return(double(success?: true))
    
    expect {
      SessionSpawner.spawn(card, column_config)
    }.to change(CardSession, :count).by(1)
  end
end
```

## Build Order

1. Migrations
2. Models + validations
3. Service objects (SessionSpawner)
4. Controllers
5. Relay server
6. JavaScript controller
7. Views/UI
8. Tests
9. Documentation