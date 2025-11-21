require "rails_helper"

RSpec.describe "Guilds", type: :request do
  describe "POST /guilds" do
    it "creates a guild" do
      user = create(:user)
      sign_in user, scope: :user

      expect do
        post guilds_path, params: {guild: {name: "Heroes", motto: "For glory"}}
      end.to change(Guild, :count).by(1)
    end
  end
end
