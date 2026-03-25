class AgentOrchestrator::BoardConfigsController < ApplicationController
  include BoardScoped
  before_action :ensure_permission_to_admin_board

  def show
    redirect_to edit_board_agent_config_path(@board)
  end

  def edit
    @agent_config = FizzyAgentOrchestrator::BoardConfig.find_or_initialize_by(board_id: @board.id)
  end

  def update
    @agent_config = FizzyAgentOrchestrator::BoardConfig.find_or_initialize_by(board_id: @board.id)
    if @agent_config.update(agent_config_params)
      redirect_to edit_board_path(@board), notice: "Agent settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def agent_config_params
    params.require(:board_config).permit(
      :system_prompt,
      :closed_prompt, :closed_auto_spawn,
      :not_now_prompt, :not_now_auto_spawn
    )
  end
end
