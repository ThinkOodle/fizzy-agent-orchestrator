module FizzyAgentOrchestrator
  class BoardConfig < ApplicationRecord
    self.table_name = "fizzy_agent_orchestrator_board_configs"

    # Don't use belongs_to - Fizzy scopes boards through Current.user
    # Just validate the ID is present
    validates :board_id, presence: true, uniqueness: true
    # system_prompt is optional

    def closed_context(card)
      build_special_state_context(card, closed_prompt)
    end

    def not_now_context(card)
      build_special_state_context(card, not_now_prompt)
    end

    private

    def build_special_state_context(card, state_prompt)
      parts = []
      parts << system_prompt if system_prompt.present?
      if state_prompt.present?
        parts << "---"
        parts << state_prompt
      end
      parts << ""
      parts << "Card: #{card.title}"
      parts << "Description: #{card.description}" if card.description.present?
      parts.join("\n")
    end
  end
end
