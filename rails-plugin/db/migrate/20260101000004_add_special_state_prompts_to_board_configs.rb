class AddSpecialStatePromptsToBoardConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :fizzy_agent_orchestrator_board_configs, :closed_prompt, :text
    add_column :fizzy_agent_orchestrator_board_configs, :not_now_prompt, :text
    add_column :fizzy_agent_orchestrator_board_configs, :closed_auto_spawn, :boolean, default: false, null: false
    add_column :fizzy_agent_orchestrator_board_configs, :not_now_auto_spawn, :boolean, default: false, null: false
  end
end
