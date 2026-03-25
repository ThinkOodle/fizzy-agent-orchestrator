module FizzyAgentOrchestrator
  class CardSession < ApplicationRecord
    self.table_name = "fizzy_agent_orchestrator_card_sessions"

    # Don't use belongs_to - Fizzy scopes cards through Current.user
    enum :status, { pending: 0, running: 1, completed: 2, failed: 3, stopped: 4 }

    validates :card_id, presence: true

    def session_key
      "hook:fizzy:card-#{card_id}"
    end

    def active?
      pending? || running?
    end
  end
end
