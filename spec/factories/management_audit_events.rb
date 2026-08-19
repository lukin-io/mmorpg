# frozen_string_literal: true

FactoryBot.define do
  factory :management_audit_event do
    association :actor, factory: [:user, :admin]
    action { "update" }
    record_type { "MapTileTemplate" }
    sequence(:record_id)
    record_label { "Outpost Surroundings [7, 7]" }
    change_set { {"passable" => {"from" => true, "to" => false}} }
    metadata { {"source" => "manage_namespace"} }
  end
end
