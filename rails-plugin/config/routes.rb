Rails.application.routes.draw do
  resources :boards, only: [] do
    resource :agent_config,
      only: [:show, :edit, :update],
      controller: "agent_orchestrator/board_configs"

    resources :columns, only: [] do
      resource :agent_config,
        only: [:show, :edit, :update],
        controller: "agent_orchestrator/column_configs"
    end
  end
end
