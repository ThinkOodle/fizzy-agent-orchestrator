class CreateFizzyOpenclawCardSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :fizzy_openclaw_card_sessions do |t|
      t.bigint :card_id, null: false
      t.integer :status, default: 0, null: false
      t.integer :last_event_seq, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :fizzy_openclaw_card_sessions, :card_id
    add_index :fizzy_openclaw_card_sessions, [:card_id, :status]
  end
end
