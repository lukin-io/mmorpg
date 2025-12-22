# frozen_string_literal: true

FactoryBot.define do
  factory :arena_season do
    sequence(:name) { |n| "Season #{n}" }
    sequence(:slug) { |n| "season-#{n}" }
    status { :live }
    starts_at { 1.month.ago }
    ends_at { 1.month.from_now }

    trait :scheduled do
      status { :scheduled }
      starts_at { 1.week.from_now }
      ends_at { 2.months.from_now }
    end

    trait :live do
      status { :live }
      starts_at { 1.month.ago }
      ends_at { 1.month.from_now }
    end

    trait :completed do
      status { :completed }
      starts_at { 3.months.ago }
      ends_at { 1.month.ago }
    end

    trait :archived do
      status { :archived }
      starts_at { 6.months.ago }
      ends_at { 3.months.ago }
    end
  end
end
