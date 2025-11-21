require "rails_helper"

RSpec.describe User, type: :model do
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  it "supports role assignment" do
    user = create(:user)
    user.add_role(:admin)

    expect(user.has_role?(:admin)).to be(true)
  end
end
