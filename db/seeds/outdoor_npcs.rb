# frozen_string_literal: true

require_relative "starter_encounter_bootstrap"

if defined?(TileNpc) && defined?(NpcTemplate)
  seeded_tile_npc_ids = []
  outdoor_npc_templates = {}
  placement_metadata_keys = %i[
    active combat_profile encounter_count encounter_experience_reward encounter_rosters
    encounter_selection_mode passive_delay_windows trauma_percent
  ].freeze

  Game::World::OutdoorNpcConfig.config.each_value do |zone_config|
    template_definitions = Array(zone_config[:npc_templates]) + Array(zone_config[:npcs])
    template_definitions.each do |npc_data|
      source_metadata = (npc_data[:metadata] || {}).except(*placement_metadata_keys)
      template_metadata = {
        "health" => npc_data[:hp],
        "base_damage" => npc_data[:damage],
        "xp_reward" => npc_data[:xp],
        "loot_table" => npc_data[:loot] || [],
        "respawn_seconds" => npc_data[:respawn_seconds],
        "respawn_variance_seconds" => npc_data[:respawn_variance_seconds],
        "seed_source" => "outdoor_npcs.yml"
      }.compact.merge(source_metadata.deep_stringify_keys)

      template = NpcTemplate.find_by(npc_key: npc_data[:key].to_s) ||
        NpcTemplate.find_by(name: npc_data[:name].to_s) ||
        NpcTemplate.new
      template.assign_attributes(
        npc_key: npc_data[:key].to_s,
        name: npc_data[:name].to_s,
        role: npc_data[:role].to_s,
        level: npc_data[:level],
        dialogue: npc_data[:dialogue].presence || "...",
        metadata: template_metadata
      )
      template.save!
      outdoor_npc_templates[npc_data[:key].to_s] = template
    end
  end

  Game::World::OutdoorNpcConfig.config.each_value do |zone_config|
    zone_name = zone_config[:zone_name].to_s

    Array(zone_config[:npcs]).each do |npc_data|
      template = outdoor_npc_templates.fetch(npc_data[:key].to_s)
      placement_metadata = (npc_data[:metadata] || {}).deep_stringify_keys.merge(
        "seed_source" => "outdoor_npcs.yml"
      )
      tile_npc = TileNpc.find_or_initialize_by(zone: zone_name, x: npc_data[:x], y: npc_data[:y])
      tile_npc.assign_attributes(
        npc_template: template,
        npc_key: npc_data[:key].to_s,
        npc_role: npc_data[:role].to_s,
        level: npc_data[:level],
        max_hp: npc_data[:hp],
        metadata: placement_metadata
      )
      tile_npc.current_hp = npc_data[:hp] if tile_npc.new_record? || tile_npc.current_hp.nil?
      tile_npc.save!
      seeded_tile_npc_ids << tile_npc.id
    end
  end

  # Entrances and managed cell state are already present before this phase.
  # Derived profiles are a bootstrap, unlike the two explicit captured anchors
  # above: do not reset existing placement state on a subsequent seed run.
  Game::World::OutdoorNpcConfig.config.each_value do |zone_config|
    seeded_tile_npc_ids.concat(Seeds::StarterEncounterBootstrap.new(
      zone_name: zone_config[:zone_name].to_s,
      definitions: Array(zone_config[:starter_npcs]),
      templates: outdoor_npc_templates
    ).call)
  end

  TileNpc.where("metadata ->> 'seed_source' = ?", "outdoor_npcs.yml")
    .where("COALESCE(metadata ->> 'seed_scope', '') != ?", Seeds::StarterEncounterBootstrap::SCOPE)
    .where.not(id: seeded_tile_npc_ids)
    .destroy_all
end
