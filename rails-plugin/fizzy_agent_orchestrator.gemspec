Gem::Specification.new do |s|
  s.name        = "fizzy_agent_orchestrator"
  s.version     = "0.1.0"
  s.authors     = ["ThinkOodle"]
  s.email       = ["sheldon@heyoodle.com"]
  s.homepage    = "https://github.com/ThinkOodle/fizzy-agent-orchestrator"
  s.summary     = "AI Agent Orchestrator for Fizzy"
  s.description = "Adds per-board and per-column AI agent configuration to Fizzy, with live session observability via OpenClaw."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 7.0"
end
