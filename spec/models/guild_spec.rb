require "rails_helper"

RSpec.describe Guild, type: :model do
  it "assigns slug on create" do
    guild = create(:guild, slug: nil)

    expect(guild.slug).to eq(guild.name.parameterize)
  end

  it "tracks treasury balances" do
    guild = create(:guild, treasury_gold: 100)

    expect { guild.update_treasury!(:gold, 50) }.to change { guild.reload.treasury_gold }.by(50)
  end
end
