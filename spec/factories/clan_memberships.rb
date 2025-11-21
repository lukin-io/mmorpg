FactoryBot.define do
  factory :clan_membership do
    clan
    user
    role { :member }
  end
end
