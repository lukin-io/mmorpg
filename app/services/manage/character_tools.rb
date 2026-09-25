# frozen_string_literal: true

module Manage
  # Admin tools: inject level (honest progression + combat rating) and grant
  # thematic set kits into the backpack only (no auto-equip).
  class CharacterTools
    Result = Struct.new(:success, :message, :character, keyword_init: true)

    def initialize(character:)
      @character = character
    end

    def inject_level!(target_level)
      target = target_level.to_i
      max = Game::Progression::Catalog.maximum_supported_level
      return failure(I18n.t("manage.characters.level_range", max:)) unless target.between?(0, max)

      character.with_lock do
        character.reload
        from = character.level.to_i
        if target > from
          raise_to_level!(target)
        elsif target < from
          lower_to_level!(target)
        end
        character.assign_base_vitals_from_stats
        character.current_hp = character.max_hp
        character.current_mp = character.max_mp
        rating = recompute_combat_rating!
        character.save!
        success(
          I18n.t(
            "manage.characters.level_injected",
            from:,
            to: character.level,
            rating:
          )
        )
      end
    end

    def grant_set_kit!(set_id:, tier: 5)
      set_id = set_id.to_s
      tier = tier.to_i
      unless Game::Equipment::SetBonuses::SET_META.key?(set_id)
        return failure(I18n.t("manage.characters.unknown_set"))
      end

      keys = Game::World::NpcLoadout::PIECE_SUFFIXES.map { |suffix| "set-#{set_id}-#{suffix}-t#{tier}" }
      templates = ItemTemplate.where(key: keys).to_a
      return failure(I18n.t("manage.characters.set_pieces_missing")) if templates.empty?

      inventory = character.inventory || character.create_inventory!
      granted = 0
      ActiveRecord::Base.transaction do
        templates.each do |template|
          Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: 1)
          granted += 1
        end
      end

      success(I18n.t("manage.characters.kit_granted", granted:, set: set_id, tier:))
    end

    def set_inquisition!(enabled:)
      character.with_lock do
        character.reload
        meta = character.metadata.to_h
        if enabled
          meta[Game::Combat::InquisitionImmunity::METADATA_KEY] = true
          meta["clan_tag"] = Game::Combat::InquisitionImmunity::CLAN_TAG
          meta["clan_system_kind"] = "inquisition"
        else
          meta.delete(Game::Combat::InquisitionImmunity::METADATA_KEY)
          meta.delete("clan_tag") if meta["clan_tag"].to_s.upcase == "INQ"
          meta.delete("clan_system_kind") if meta["clan_system_kind"].to_s == "inquisition"
        end
        character.update!(metadata: meta)
      end
      success(I18n.t(enabled ? "manage.characters.inq_on" : "manage.characters.inq_off"))
    end

    private

    attr_reader :character

    def raise_to_level!(target)
      while character.level.to_i < target
        next_level = character.level.to_i + 1
        threshold = Character.xp_required_for_level(next_level)
        break unless threshold

        needed = [threshold - character.experience.to_i, 0].max
        Players::Progression::LevelUpService.new(character:).apply_experience!(needed)
        character.reload
        break if character.level.to_i < next_level
      end
    end

    def lower_to_level!(target)
      rewards = Game::Progression::Catalog.rewards_for_level(target) || {}
      xp = Character.xp_required_for_level(target).to_i
      character.level = target
      character.experience = xp
      # Do not invent free stats on demote; keep existing unspent points.
      character.metadata = character.metadata.to_h.merge(
        "combat_rating" => 0,
        "inject_level_demoted_at" => Time.current.iso8601(6),
        "inject_level_rewards_snapshot" => rewards
      )
    end

    def recompute_combat_rating!
      rating = character.attack_power.to_i +
        character.defense.to_i +
        (character.level.to_i * 5) +
        character.equipment_effect_value("armor_class").to_i +
        character.equipment_effect_value("accuracy").to_i
      character.metadata = character.metadata.to_h.merge("combat_rating" => rating)
      rating
    end

    def success(message)
      Result.new(success: true, message:, character:)
    end

    def failure(message)
      Result.new(success: false, message:, character:)
    end
  end
end
