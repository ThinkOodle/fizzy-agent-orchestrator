module FizzyAgentOrchestrator
  module ColumnExtension
    extend ActiveSupport::Concern

    included do
      has_one :agent_config,
        class_name: "FizzyAgentOrchestrator::ColumnConfig",
        foreign_key: :column_id,
        dependent: :destroy
    end
  end
end
