FactoryBot.define do
  factory :mount_stable_slot do
    association :user
    slot_index { 0 }
    status { :unlocked }
  end
end
