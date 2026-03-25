class CreateFizzyAgentOrchestratorBoardConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :fizzy_agent_orchestrator_board_configs do |t|
      t.bigint :board_id, null: false
      t.text :system_prompt
      t.json :default_tools, default: ["file_read", "file_write"]
      t.timestamps
    end

    add_index :fizzy_agent_orchestrator_board_configs, :board_id, unique: true
  end
end
