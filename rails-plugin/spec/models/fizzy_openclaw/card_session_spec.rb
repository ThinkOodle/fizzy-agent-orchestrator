require "spec_helper"

RSpec.describe FizzyOpenclaw::CardSession do
  describe "#session_key" do
    it "returns the expected key format" do
      session = FizzyOpenclaw::CardSession.new(card_id: 42)
      expect(session.session_key).to eq("hook:fizzy:card-42")
    end
  end

  describe "#active?" do
    it "returns true for pending status" do
      session = FizzyOpenclaw::CardSession.new(status: :pending)
      expect(session.active?).to be true
    end

    it "returns true for running status" do
      session = FizzyOpenclaw::CardSession.new(status: :running)
      expect(session.active?).to be true
    end

    it "returns false for stopped status" do
      session = FizzyOpenclaw::CardSession.new(status: :stopped)
      expect(session.active?).to be false
    end

    it "returns false for completed status" do
      session = FizzyOpenclaw::CardSession.new(status: :completed)
      expect(session.active?).to be false
    end
  end

  describe "status enum" do
    it "has correct status values" do
      expect(FizzyOpenclaw::CardSession.statuses).to eq(
        "pending" => 0, "running" => 1, "completed" => 2, "failed" => 3, "stopped" => 4
      )
    end
  end
end
