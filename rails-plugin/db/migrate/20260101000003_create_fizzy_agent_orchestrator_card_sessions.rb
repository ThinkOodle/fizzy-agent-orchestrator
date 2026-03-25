class CreateFizzyAgentOrchestratorCardSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :fizzy_agent_orchestrator_card_sessions do |t|
      t.bigint :card_id, null: false
      t.integer :status, default: 0, null: false
      t.integer :last_event_seq, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :fizzy_agent_orchestrator_card_sessions, :card_id,
      name: "idx_fao_card_sessions_card_id"
    add_index :fizzy_agent_orchestrator_card_sessions, [:card_id, :status],
      name: "idx_fao_card_sessions_card_status"
  end
end
