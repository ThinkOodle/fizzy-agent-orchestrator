module FizzyOpenclaw
  class BoardConfigsController < ApplicationController
    before_action :load_board
    before_action :authorize_admin!

    def edit
      @config = BoardConfig.find_or_initialize_by(board_id: @board.id)
    end

    def update
      @config = BoardConfig.find_or_initialize_by(board_id: @board.id)
      if @config.update(config_params)
        redirect_to main_app.board_path(@board), notice: "Agent configuration saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def load_board
      @board = Board.find(params[:board_id])
    end

    def authorize_admin!
      unless current_user&.admin?
        redirect_to main_app.root_path, alert: "Not authorized."
      end
    end

    def config_params
      params.require(:board_config).permit(:system_prompt, default_tools: [])
    end
  end
end
