FactoryBot.define do
  factory :auction_listing do
    association :seller, factory: :user
    item_name { "Iron Sword" }
    quantity { 1 }
    currency_type { "gold" }
    starting_bid { 100 }
    status { :active }
    ends_at { 1.day.from_now }
  end
end
