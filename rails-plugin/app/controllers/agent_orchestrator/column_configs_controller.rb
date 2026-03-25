class AgentOrchestrator::ColumnConfigsController < ApplicationController
  include BoardScoped
  before_action :set_column
  before_action :ensure_permission_to_admin_board

  def show
    redirect_to edit_board_column_agent_config_path(@board, @column)
  end

  def edit
    @agent_config = FizzyAgentOrchestrator::ColumnConfig.find_or_initialize_by(column_id: @column.id)
  end

  def update
    @agent_config = FizzyAgentOrchestrator::ColumnConfig.find_or_initialize_by(column_id: @column.id)
    if @agent_config.update(agent_config_params)
      redirect_to board_path(@board), notice: "Column agent settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_column
    @column = @board.columns.find(params[:column_id])
  end

  def agent_config_params
    params.require(:column_config).permit(:system_prompt, :auto_spawn, :timeout_minutes)
  end
end
