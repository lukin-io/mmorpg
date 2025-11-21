require "rails_helper"

RSpec.describe Trades::SessionManager do
  it "starts and confirms a session" do
    initiator = create(:user)
    recipient = create(:user)
    manager = described_class.new(initiator:, recipient:)

    session = manager.start!
    expect(session).to be_pending

    expect do
      manager.confirm!(session:, actor: initiator)
    end.to change { session.reload.status }.from("pending").to("confirming")
  end
end
