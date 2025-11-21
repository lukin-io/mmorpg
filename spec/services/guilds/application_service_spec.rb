require "rails_helper"

RSpec.describe Guilds::ApplicationService do
  describe "#approve!" do
    it "creates membership when approving" do
      guild = create(:guild)
      applicant = create(:user)
      guild.guild_applications.create!(applicant:, answers: {bio: "hi"})
      reviewer = guild.leader

      service = described_class.new(guild:, applicant:)
      expect { service.approve!(reviewer:) }.to change { guild.guild_memberships.count }.by(1)
    end
  end
end
