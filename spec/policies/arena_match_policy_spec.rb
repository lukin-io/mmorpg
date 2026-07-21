# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaMatchPolicy do
  let(:participant_user) { create(:user) }
  let(:participant) { create(:character, user: participant_user) }
  let(:match) { create(:arena_match, :live) }

  before do
    create(:arena_participation,
      arena_match: match,
      character: participant,
      user: participant_user,
      team: "a")
  end

  it "allows a live participant to submit surrender through the shared action" do
    expect(described_class.new(participant_user, match)).to be_action
  end

  it "rejects a non-participant and an anonymous user" do
    expect(described_class.new(create(:user), match)).not_to be_action
    expect(described_class.new(nil, match)).not_to be_action
  end

  it "rejects actions after the match is completed" do
    match.update!(status: :completed, ended_at: Time.current)

    expect(described_class.new(participant_user, match)).not_to be_action
  end
end
