class FixStringForeignKeys < ActiveRecord::Migration[7.0]
  def up
    # Helper: check if a column is an integer type
    # board_configs: bigint board_id -> string
    board_col = connection.columns(:fizzy_agent_orchestrator_board_configs).find { |c| c.name == "board_id" }
    if board_col && board_col.type == :integer
      remove_index :fizzy_agent_orchestrator_board_configs, :board_id, if_exists: true
      remove_column :fizzy_agent_orchestrator_board_configs, :board_id
      add_column :fizzy_agent_orchestrator_board_configs, :board_id, :string, null: false, default: ""
    end
    add_index :fizzy_agent_orchestrator_board_configs, :board_id, unique: true, if_not_exists: true

    # column_configs: bigint column_id -> string
    col_col = connection.columns(:fizzy_agent_orchestrator_column_configs).find { |c| c.name == "column_id" }
    if col_col && col_col.type == :integer
      remove_index :fizzy_agent_orchestrator_column_configs, :column_id, if_exists: true
      remove_column :fizzy_agent_orchestrator_column_configs, :column_id
      add_column :fizzy_agent_orchestrator_column_configs, :column_id, :string, null: false, default: ""
    end
    add_index :fizzy_agent_orchestrator_column_configs, :column_id, unique: true, if_not_exists: true

    # card_sessions: bigint card_id -> string
    card_col = connection.columns(:fizzy_agent_orchestrator_card_sessions).find { |c| c.name == "card_id" }
    if card_col && card_col.type == :integer
      remove_index :fizzy_agent_orchestrator_card_sessions, :card_id,
        name: "idx_fao_card_sessions_card_id", if_exists: true
      remove_index :fizzy_agent_orchestrator_card_sessions,
        name: "idx_fao_card_sessions_card_status", if_exists: true
      remove_column :fizzy_agent_orchestrator_card_sessions, :card_id
      add_column :fizzy_agent_orchestrator_card_sessions, :card_id, :string, null: false, default: ""
    end
    add_index :fizzy_agent_orchestrator_card_sessions, :card_id,
      name: "idx_fao_card_sessions_card_id", if_not_exists: true
    add_index :fizzy_agent_orchestrator_card_sessions, [:card_id, :status],
      name: "idx_fao_card_sessions_card_status", if_not_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
