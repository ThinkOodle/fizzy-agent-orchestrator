module FizzyOpenclaw
  class BoardConfig < ApplicationRecord
    self.table_name = "fizzy_openclaw_board_configs"

    belongs_to :board

    validates :board_id, presence: true, uniqueness: true
    validates :system_prompt, presence: true
  end
end
