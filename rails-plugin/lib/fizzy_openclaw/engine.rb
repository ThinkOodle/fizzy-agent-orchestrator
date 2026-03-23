module FizzyOpenclaw
  class Engine < ::Rails::Engine
    isolate_namespace FizzyOpenclaw

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
    end

    initializer "fizzy_openclaw.extend_card_model" do
      config.to_prepare do
        if defined?(Card)
          Card.include FizzyOpenclaw::CardExtension
        end
      end
    end
  end
end
