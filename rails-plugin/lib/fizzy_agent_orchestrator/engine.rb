module FizzyAgentOrchestrator
  class Engine < ::Rails::Engine
    isolate_namespace FizzyAgentOrchestrator

    # Make engine migrations available to the host app
    # Users run: bin/rails fizzy_agent_orchestrator:install:migrations
    initializer "fizzy_agent_orchestrator.migrations" do |app|
      unless app.root.to_s == root.to_s
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end

    # Auto-include CardExtension into Fizzy's Card model
    initializer "fizzy_agent_orchestrator.extend_models" do
      config.to_prepare do
        if defined?(Card)
          Card.include FizzyAgentOrchestrator::CardExtension unless Card.ancestors.include?(FizzyAgentOrchestrator::CardExtension)
        end
        if defined?(Board)
          Board.include FizzyAgentOrchestrator::BoardExtension unless Board.ancestors.include?(FizzyAgentOrchestrator::BoardExtension)
        end
        if defined?(Column)
          Column.include FizzyAgentOrchestrator::ColumnExtension unless Column.ancestors.include?(FizzyAgentOrchestrator::ColumnExtension)
        end
      end
    end
  end
end
