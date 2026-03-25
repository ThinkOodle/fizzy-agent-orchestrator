module FizzyAgentOrchestrator
  module ClosureExtension
    extend ActiveSupport::Concern

    included do
      after_create_commit :spawn_openclaw_agent_for_closed_state
    end

    private

    def spawn_openclaw_agent_for_closed_state
      card.spawn_openclaw_agent_for_state(:closed) if card.respond_to?(:spawn_openclaw_agent_for_state)
    end
  end
end
