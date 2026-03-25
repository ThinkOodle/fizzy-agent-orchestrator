class CreateFizzyAgentOrchestratorColumnConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :fizzy_agent_orchestrator_column_configs do |t|
      t.bigint :column_id, null: false
      t.text :system_prompt
      t.boolean :auto_spawn, default: false, null: false
      t.integer :timeout_minutes, default: 30, null: false
      t.json :allowed_tools
      t.timestamps
    end

    add_index :fizzy_agent_orchestrator_column_configs, :column_id, unique: true
  end
end
