require "spec_helper"

RSpec.describe FizzyOpenclaw::ColumnConfig do
  describe "validations" do
    it "requires system_prompt when auto_spawn is true" do
      config = FizzyOpenclaw::ColumnConfig.new(column_id: 1, auto_spawn: true)
      expect(config).not_to be_valid
      expect(config.errors[:system_prompt]).to include("can't be blank")
    end

    it "does not require system_prompt when auto_spawn is false" do
      config = FizzyOpenclaw::ColumnConfig.new(column_id: 1, auto_spawn: false, timeout_minutes: 30)
      expect(config).to be_valid
    end

    it "validates timeout_minutes is positive" do
      config = FizzyOpenclaw::ColumnConfig.new(column_id: 1, timeout_minutes: 0)
      expect(config).not_to be_valid
    end

    it "validates timeout_minutes max 120" do
      config = FizzyOpenclaw::ColumnConfig.new(column_id: 1, timeout_minutes: 121)
      expect(config).not_to be_valid
    end
  end
end
