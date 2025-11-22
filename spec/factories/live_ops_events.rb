FactoryBot.define do
  factory :live_ops_event, class: "LiveOps::Event" do
    requested_by { association :user, :moderator }
    event_type { :spawn_npc }
    status { :pending }
    severity { :normal }
    payload { {"npc_key" => "gm_guard", "zone_key" => "ashen_forest", "location" => "(0,0)"} }
  end
end
