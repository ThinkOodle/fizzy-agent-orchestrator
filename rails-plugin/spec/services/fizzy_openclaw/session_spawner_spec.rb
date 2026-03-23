require "spec_helper"

RSpec.describe FizzyOpenclaw::SessionSpawner do
  let(:board) do
    double("Board", id: 10, name: "Dev Board")
  end

  let(:column) do
    double("Column", id: 5, name: "In Progress", board: board)
  end

  let(:card) do
    double("Card", id: 1, number: 42, title: "Fix the bug", description: "It crashes")
  end

  let(:column_config) do
    instance_double(
      FizzyOpenclaw::ColumnConfig,
      column: column,
      system_prompt: "Investigate and fix the issue.",
      timeout_minutes: 30,
      allowed_tools: ["file_read", "file_write"]
    )
  end

  let(:board_config) do
    instance_double(FizzyOpenclaw::BoardConfig, system_prompt: "You are a Rails engineer.")
  end

  before do
    allow(FizzyOpenclaw::BoardConfig).to receive(:find_by).with(board_id: 10).and_return(board_config)
    allow(FizzyOpenclaw::CardSession).to receive(:find_by).and_return(nil)

    fake_session = instance_double(FizzyOpenclaw::CardSession, id: 99, status: "running")
    allow(FizzyOpenclaw::CardSession).to receive(:create!).and_return(fake_session)
    allow(fake_session).to receive(:update!)
  end

  describe ".spawn" do
    context "when OpenClaw responds with 200" do
      before do
        fake_response = double("response", code: "200", body: "{}")
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(fake_response)
      end

      it "creates a CardSession" do
        expect(FizzyOpenclaw::CardSession).to receive(:create!).with(
          hash_including(card_id: 1, status: :pending)
        ).and_call_original

        FizzyOpenclaw::SessionSpawner.spawn(card, column_config)
      end

      it "returns the session" do
        result = FizzyOpenclaw::SessionSpawner.spawn(card, column_config)
        expect(result).not_to be_nil
      end
    end

    context "when OpenClaw responds with error" do
      before do
        fake_response = double("response", code: "500", body: "Internal server error")
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(fake_response)
        allow(Rails.logger).to receive(:error)
      end

      it "returns nil" do
        result = FizzyOpenclaw::SessionSpawner.spawn(card, column_config)
        expect(result).to be_nil
      end
    end

    context "when HTTP request raises an exception" do
      before do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Net::OpenTimeout)
        allow(Rails.logger).to receive(:error)
      end

      it "returns nil without raising" do
        expect { FizzyOpenclaw::SessionSpawner.spawn(card, column_config) }.not_to raise_error
        expect(FizzyOpenclaw::SessionSpawner.spawn(card, column_config)).to be_nil
      end
    end
  end
end
