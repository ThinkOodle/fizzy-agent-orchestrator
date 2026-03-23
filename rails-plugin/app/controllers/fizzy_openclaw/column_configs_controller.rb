module FizzyOpenclaw
  class ColumnConfigsController < ApplicationController
    before_action :load_column
    before_action :authorize_admin!

    def edit
      @config = ColumnConfig.find_or_initialize_by(column_id: @column.id)
    end

    def update
      @config = ColumnConfig.find_or_initialize_by(column_id: @column.id)
      if @config.update(config_params)
        redirect_back fallback_location: main_app.root_path, notice: "Column agent config saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def load_column
      @column = Column.find(params[:column_id])
    end

    def authorize_admin!
      unless current_user&.admin?
        redirect_to main_app.root_path, alert: "Not authorized."
      end
    end

    def config_params
      params.require(:column_config).permit(:system_prompt, :auto_spawn, :timeout_minutes, allowed_tools: [])
    end
  end
end
