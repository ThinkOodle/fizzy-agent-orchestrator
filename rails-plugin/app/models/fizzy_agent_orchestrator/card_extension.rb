module FizzyAgentOrchestrator
  module CardExtension
    extend ActiveSupport::Concern

    included do
      has_one :openclaw_card_session,
              class_name: "FizzyAgentOrchestrator::CardSession",
              foreign_key: :card_id,
              dependent: :destroy

      after_update :spawn_openclaw_agent, if: :saved_change_to_column_id?
    end

    def openclaw_column_config
      return unless respond_to?(:column) && column.present?
      FizzyAgentOrchestrator::ColumnConfig.find_by(column_id: column_id)
    end

    def openclaw_board_config
      FizzyAgentOrchestrator::BoardConfig.find_by(board_id: board_id)
    end

    # Called externally by ClosureExtension / NotNowExtension hooks
    def spawn_openclaw_agent_for_state(state)
      board_config = openclaw_board_config
      return unless board_config

      case state
      when :closed
        return unless board_config.closed_auto_spawn?
      when :not_now
        return unless board_config.not_now_auto_spawn?
      else
        return
      end

      SessionSpawner.spawn_for_special_state(self, board_config, state)
    end

    private

    def spawn_openclaw_agent
      config = openclaw_column_config
      return unless config&.auto_spawn?

      SessionSpawner.spawn(self, config)
    end
  end
end
