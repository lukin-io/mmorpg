# frozen_string_literal: true

module Game
  module World
    # Read-only source captures for city services whose economic mutations are
    # intentionally deferred. The general Shop and Arena retain dedicated UIs.
    class CityBuildingCatalog
      BUILDINGS = {
        "market" => {
          "title" => "Market",
          "kind" => "market",
          "summary" => "Player listings and rented stalls.",
          "stall_tiers" => [
            ["Newspaper display", 0, 100, 400, "15%"],
            ["Small", 200, 250, 500, "5%"],
            ["Medium", 400, 450, 750, "4%"],
            ["Spacious", 600, 700, 1000, "3%"],
            ["Large", 800, 1000, 1250, "2%"],
            ["Huge", 1000, 2000, 1500, "1%"]
          ]
        },
        "junk_dealer" => {
          "title" => "Junk Dealer",
          "kind" => "shop_shell",
          "summary" => "Captured shop shell; stock was not loaded.",
          "modes" => ["Buy goods", "Licenses", "Sell goods", "For beginners"]
        },
        "numismatics" => {
          "title" => "Numismatics Shop",
          "kind" => "numismatics",
          "summary" => "Single-commodity player listing book.",
          "commodity" => "Ancient Alvian Coin"
        },
        "airship_station" => {
          "title" => "Oktal Airship Station",
          "kind" => "airship",
          "summary" => "Scheduled routes; ticket purchase and boarding are deferred.",
          "routes" => [
            ["Forpost", 150],
            ["Khalgan Fair", 200]
          ]
        },
        "hospital" => {
          "title" => "Hospital",
          "kind" => "hospital",
          "summary" => "Treatment shop, restricted recovery rooms, and pharmacy processing.",
          "tabs" => ["Shop", "Rest room", "Hospital bed", "Pharmacy"],
          "goods" => [
            ["Beginner healer bag", "10 light injuries", 300, 33],
            ["Skilled healer bag", "10 medium injuries", 750, 28],
            ["Experienced healer bag", "10 heavy injuries", 1500, 143],
            ["Combat first-aid kit", "1 combat injury", 7000, 1]
          ]
        }
      }.freeze

      class << self
        def fetch(building_key)
          BUILDINGS[building_key.to_s]
        end

        def key?(building_key)
          BUILDINGS.key?(building_key.to_s)
        end

        def path_for(building_key)
          "/city/buildings/#{building_key}" if key?(building_key)
        end

        def accessible?(character:, building_key:)
          return false unless key?(building_key)

          position = CharacterPosition.includes(:zone).find_by(character_id: character&.id)
          return false unless position&.zone&.city?

          CityHotspot.for_zone(position.zone).any? do |hotspot|
            hotspot.action_params.to_h["feature"] == building_key.to_s &&
              hotspot.can_interact?(character)
          end
        end
      end
    end
  end
end
