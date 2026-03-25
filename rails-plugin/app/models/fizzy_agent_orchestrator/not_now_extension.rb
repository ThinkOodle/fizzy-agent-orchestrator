module FizzyAgentOrchestrator
  module NotNowExtension
    extend ActiveSupport::Concern

    included do
      after_create_commit :spawn_openclaw_agent_for_not_now_state
    end

    private

    def spawn_openclaw_agent_for_not_now_state
      card.spawn_openclaw_agent_for_state(:not_now) if card.respond_to?(:spawn_openclaw_agent_for_state)
    end
  end
end
