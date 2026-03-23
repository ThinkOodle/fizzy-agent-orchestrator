module FizzyOpenclaw
  module CardExtension
    extend ActiveSupport::Concern

    included do
      has_one :openclaw_card_session,
              class_name: "FizzyOpenclaw::CardSession",
              foreign_key: :card_id,
              dependent: :destroy

      after_update :spawn_openclaw_agent, if: :saved_change_to_column_id?
    end

    def openclaw_column_config
      return unless respond_to?(:column) && column.present?
      FizzyOpenclaw::ColumnConfig.find_by(column_id: column_id)
    end

    private

    def spawn_openclaw_agent
      config = openclaw_column_config
      return unless config&.auto_spawn?

      SessionSpawner.spawn(self, config)
    end
  end
end
