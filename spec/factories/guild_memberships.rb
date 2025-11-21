FactoryBot.define do
  factory :guild_membership do
    guild
    user
    role { :member }
    status { :active }
  end
end
