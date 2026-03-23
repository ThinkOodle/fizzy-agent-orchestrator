require "spec_helper"

RSpec.describe FizzyOpenclaw::BoardConfig do
  describe "validations" do
    it "requires system_prompt" do
      config = FizzyOpenclaw::BoardConfig.new(board_id: 1)
      expect(config).not_to be_valid
      expect(config.errors[:system_prompt]).to include("can't be blank")
    end

    it "requires unique board_id" do
      FizzyOpenclaw::BoardConfig.create!(board_id: 1, system_prompt: "test")
      dupe = FizzyOpenclaw::BoardConfig.new(board_id: 1, system_prompt: "other")
      expect(dupe).not_to be_valid
    end

    it "is valid with board_id and system_prompt" do
      config = FizzyOpenclaw::BoardConfig.new(board_id: 99, system_prompt: "You are a helper.")
      expect(config).to be_valid
    end
  end
end
