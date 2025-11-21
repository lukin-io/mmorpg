require "rails_helper"

RSpec.describe Role, type: :model do
  it "links to users" do
    role = create(:role)
    user = create(:user)

    user.roles << role

    expect(user.roles).to include(role)
  end
end
