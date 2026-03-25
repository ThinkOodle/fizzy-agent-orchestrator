FizzyAgentOrchestrator::Engine.routes.draw do
  resources :boards, only: [] do
    resource :agent_config,
      only: [:show, :edit, :update],
      controller: "board_configs",
      as: :board_agent_config
  end

  resources :columns, only: [] do
    resource :agent_config,
      only: [:show, :edit, :update],
      controller: "column_configs",
      as: :column_agent_config
  end

  resources :cards, only: [] do
    member do
      post :start_agent
      post :stop_agent
    end
  end

  # Relay proxy — Fizzy polls this and we forward to relay
  get "events", to: "agent_sessions#events"
end
