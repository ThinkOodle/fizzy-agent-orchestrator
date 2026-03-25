Gem::Specification.new do |s|
  s.name        = "fizzy_agent_orchestrator"
  s.version     = "0.1.0"
  s.authors     = ["Oodle"]
  s.summary     = "AI agent integration for Fizzy via OpenClaw"
  s.description = "Enables AI agents on Fizzy cards with per-column context configuration"

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 7.0"
  s.add_dependency "httparty"

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_bot_rails"
end
