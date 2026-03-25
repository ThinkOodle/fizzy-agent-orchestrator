module FizzyAgentOrchestrator
  class ColumnConfig < ApplicationRecord
    self.table_name = "fizzy_agent_orchestrator_column_configs"

    # Don't use belongs_to - Fizzy scopes columns through Current.user
    validates :column_id, presence: true, uniqueness: true
    validates :system_prompt, presence: true, if: -> { auto_spawn? }
    validates :timeout_minutes, numericality: { greater_than: 0, less_than_or_equal_to: 120 }

    def build_context(card)
      # Look up board config via the board that owns this column
      board = Current.account.boards.find { |b| b.columns.any? { |c| c.id == column_id } }
      board_config = board&.openclaw_board_config
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
