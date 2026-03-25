module FizzyAgentOrchestrator
  class BoardConfig < ApplicationRecord
    self.table_name = "fizzy_agent_orchestrator_board_configs"

    belongs_to :board

    validates :board_id, presence: true, uniqueness: true
    validates :system_prompt, presence: true
  end
end
