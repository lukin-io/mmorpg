FactoryBot.define do
  factory :friendship do
    association :requester, factory: :user
    association :receiver, factory: :user
    status { :pending }
  end
end
