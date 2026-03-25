class FixStringForeignKeys < ActiveRecord::Migration[7.0]
  def change
    # board_configs: bigint board_id -> string
    remove_column :fizzy_agent_orchestrator_board_configs, :board_id
    add_column :fizzy_agent_orchestrator_board_configs, :board_id, :string, null: false, default: ""
    add_index :fizzy_agent_orchestrator_board_configs, :board_id, unique: true

    # column_configs: bigint column_id -> string
    remove_column :fizzy_agent_orchestrator_column_configs, :column_id
    add_column :fizzy_agent_orchestrator_column_configs, :column_id, :string, null: false, default: ""
    add_index :fizzy_agent_orchestrator_column_configs, :column_id, unique: true

    # card_sessions: bigint card_id -> string
    remove_column :fizzy_agent_orchestrator_card_sessions, :card_id
    add_column :fizzy_agent_orchestrator_card_sessions, :card_id, :string, null: false, default: ""
    add_index :fizzy_agent_orchestrator_card_sessions, :card_id, name: "idx_fao_card_sessions_card_id"
    add_index :fizzy_agent_orchestrator_card_sessions, [:card_id, :status], name: "idx_fao_card_sessions_card_status"
  end
end
