FizzyOpenclaw::Engine.routes.draw do
  resources :boards, only: [] do
    resource :agent_config, only: [:edit, :update], controller: "board_configs"
  end

  resources :columns, only: [] do
    resource :agent_config, only: [:edit, :update], controller: "column_configs"
  end

  resources :cards, only: [] do
    member do
      post :start_agent
      post :stop_agent
    end
  end

  get "/events", to: "agent_sessions#events"
end
