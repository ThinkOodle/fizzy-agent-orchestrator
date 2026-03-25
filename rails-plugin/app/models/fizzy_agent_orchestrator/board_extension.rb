module FizzyAgentOrchestrator
  module BoardExtension
    extend ActiveSupport::Concern

    included do
      has_one :agent_config,
        class_name: "FizzyAgentOrchestrator::BoardConfig",
        foreign_key: :board_id,
        dependent: :destroy
    end
  end
end
