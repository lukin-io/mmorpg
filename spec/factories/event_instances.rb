# frozen_string_literal: true

FactoryBot.define do
  factory :event_instance do
    association :game_event
    starts_at { 1.day.from_now }
    ends_at { 2.days.from_now }
    status { :scheduled }
    announcer_npc_key { "herald_arwyn" }
    temporary_npc_keys { [] }
    metadata { {} }
  end
end
