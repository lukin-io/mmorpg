# frozen_string_literal: true

FactoryBot.define do
  factory :game_event do
    association :recipient, factory: :user
    sequence(:event_key) { |n| "system-information:#{n}" }
    event_type { :system_information }
    body { "The road is clear." }
    payload { {} }
    occurred_at { Time.current }

    trait :fight_finished do
      event_type { :fight_finished }
      body { I18n.t("game.events.fight_finished") }
      payload { {"experience" => 10} }
    end

    trait :item_found do
      event_type { :item_found }
      body { I18n.t("game.events.search_result") }
      payload { {"item_name" => "Wood Chips", "quantity" => 1} }
    end

    trait :money_found do
      event_type { :money_found }
      body { I18n.t("game.events.search_result") }
      payload { {"amount" => 24, "currency" => "NV"} }
    end

    trait :world_announcement do
      recipient { nil }
      event_type { :world_announcement }
      body { "The outpost is under attack." }
    end
  end
end
