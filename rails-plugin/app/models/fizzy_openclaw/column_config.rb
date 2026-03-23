module FizzyOpenclaw
  class ColumnConfig < ApplicationRecord
    self.table_name = "fizzy_openclaw_column_configs"

    belongs_to :column

    validates :column_id, presence: true, uniqueness: true
    validates :system_prompt, presence: true, if: -> { auto_spawn? }
    validates :timeout_minutes, numericality: { greater_than: 0, less_than_or_equal_to: 120 }

    def build_context(card)
      board_config = column.board.openclaw_board_config
      parts = []
      parts << board_config.system_prompt if board_config&.system_prompt.present?
      parts << "---"
      parts << system_prompt if system_prompt.present?
      parts << ""
      parts << "Card: #{card.title}"
      parts << "Description: #{card.description}" if card.description.present?
      parts.join("\n")
    end
  end
end
