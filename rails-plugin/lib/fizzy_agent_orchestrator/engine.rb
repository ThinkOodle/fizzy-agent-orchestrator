module FizzyAgentOrchestrator
  class Engine < ::Rails::Engine
    # NOT isolate_namespace — controllers/views/routes live in the host app context
    # so all route helpers, Current.user, BoardScoped etc work without any prefix

    # Inject migrations into host app automatically
    initializer "fizzy_agent_orchestrator.migrations" do |app|
      unless app.root.to_s == root.to_s
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end

    # Extend Fizzy models
    initializer "fizzy_agent_orchestrator.extend_models" do
      config.to_prepare do
        Card.include FizzyAgentOrchestrator::CardExtension   if defined?(Card)   && !Card.ancestors.include?(FizzyAgentOrchestrator::CardExtension)
        Board.include FizzyAgentOrchestrator::BoardExtension if defined?(Board)  && !Board.ancestors.include?(FizzyAgentOrchestrator::BoardExtension)
        Column.include FizzyAgentOrchestrator::ColumnExtension if defined?(Column) && !Column.ancestors.include?(FizzyAgentOrchestrator::ColumnExtension)
      end
    end
  end
end
