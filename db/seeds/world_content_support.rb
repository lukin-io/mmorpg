# frozen_string_literal: true

module Seeds
  # Shared capability cleanup used only while reconciling authored seed content.
  # Changed targets cancel live offers; retired targets also detach historical
  # references. Callers supply the transaction surrounding their record write.
  module WorldContentSupport
    module_function

    def city_zones
      Zone.where(location_type: "city").select do |zone|
        zone.metadata.to_h["city_key"] == Game::World::CityCatalog::CITY_KEY
      end
    end

    def zone_metadata_for(name)
      city_node = Game::World::CityCatalog::NODES.values.find { |node| node["zone_name"] == name }
      if city_node
        city_node_key = Game::World::CityCatalog::NODES.key(city_node)
        city_presentation = Game::World::CityCatalog.presentation(city_node_key)
        return {
          "city_key" => Game::World::CityCatalog::CITY_KEY,
          "city_node_key" => city_node_key,
          "title" => city_node["title"],
          "description" => "Forpost — #{city_node['title']}",
          "city_presentation" => city_presentation
        }
      end

      case name
      when "Outpost Surroundings"
        {
          "source_map" => "m_1001_999"
        }
      else
        {}
      end
    end

    def retire_action_targets(target_type, targets)
      return unless defined?(WorldActionOffer)

      target_offers = WorldActionOffer.where(target_type:, target_id: targets.select(:id))
      live_statuses = WorldActionOffer.statuses.values_at("offered", "accepted")
      target_offers.where(status: live_statuses).update_all(
        status: WorldActionOffer.statuses.fetch("cancelled"),
        error_message: "Authored world content was updated.",
        updated_at: Time.current
      )
      target_offers.update_all(target_type: nil, target_id: nil, updated_at: Time.current)
    end

    def cancel_changed_action_offers(target)
      return unless defined?(WorldActionOffer) && target.persisted? && target.has_changes_to_save?

      WorldActionOffer.where(
        target:,
        status: WorldActionOffer.statuses.values_at("offered", "accepted")
      ).update_all(
        status: WorldActionOffer.statuses.fetch("cancelled"),
        error_message: "Authored world content was updated.",
        updated_at: Time.current
      )
    end
  end
end
