# frozen_string_literal: true

# ArenaParticipation tracks combatants in arena matches.
# Supports both player characters and NPC bots.
#
# @example Player participation
#   ArenaParticipation.create!(arena_match: match, character: char, user: user, team: "a")
#
# @example NPC participation
#   ArenaParticipation.create!(arena_match: match, npc_template: npc, team: "b")
#
class ArenaParticipation < ApplicationRecord
  RESULTS = {
    pending: 0,
    victory: 1,
    defeat: 2,
    draw: 3
  }.freeze

  enum :result, RESULTS

  belongs_to :arena_match
  belongs_to :character, optional: true
  belongs_to :user, optional: true
  belongs_to :npc_template, optional: true

  validates :team, presence: true
  validate :has_character_or_npc
  validate :npc_content_validity

  scope :players, -> { where.not(character_id: nil) }
  scope :npcs, -> { where.not(npc_template_id: nil) }

  # Check if this is an NPC participant
  #
  # @return [Boolean] true if participant is an NPC
  def npc?
    npc_template_id.present?
  end

  # Check if this is a player participant
  #
  # @return [Boolean] true if participant is a player
  def player?
    character_id.present?
  end

  # Defeat is terminal for this fight. Recovery outside the turn resolver must
  # not restore a target, pending action, or side's eligibility to keep fighting.
  # A lethal committed exchange is handled separately by CombatProcessor's
  # snapshot of the participants who were alive when that exchange began.
  def combat_alive?
    !defeat? && current_hp.to_i.positive?
  end

  # Get the participant name (works for both players and NPCs)
  #
  # @return [String] the participant's name
  def participant_name
    if npc?
      npc_template&.name || "Arena Bot"
    else
      character&.name || "Unknown"
    end
  end

  # Get the participant level (works for both players and NPCs)
  #
  # @return [Integer] the participant's level
  def participant_level
    if npc?
      level_override = Integer(metadata.to_h["level"].to_s, exception: false)
      return level_override if level_override && level_override >= 0

      npc_template&.level || 0
    else
      character&.level || 1
    end
  end

  # Get current HP for the participant
  # For NPCs, this is tracked in metadata since they don't have a Character record
  #
  # @return [Integer] current HP
  def current_hp
    if npc?
      (metadata || {})["current_hp"] || max_hp
    else
      character&.current_hp || 0
    end
  end

  # Set current HP for NPC participants
  #
  # @param hp [Integer] the new HP value
  def current_hp=(hp)
    if npc?
      self.metadata ||= {}
      self.metadata["current_hp"] = [hp, 0].max
    elsif character
      character.update!(current_hp: [hp, 0].max)
    end
  end

  # Get captured NPC HP or the player's equipment-aware maximum. Reading this
  # value does not rewrite persisted base HP or refill current HP.
  #
  # @return [Integer] max HP
  def max_hp
    if npc?
      (metadata || {})["max_hp"] || npc_template&.health || 0
    else
      character&.effective_max_hp || 100
    end
  end

  # Get stats for the participant (for combat calculations)
  #
  # @return [Hash] stats hash with attack, defense, agility, etc.
  def combat_stats
    if npc?
      npc_combat_data.fetch("stats", {}).with_indifferent_access
    else
      character&.stats || Game::Systems::StatBlock.new(base: {})
    end
  end

  # Resource maximum, not the independent combat-profile magic-hit ceiling.
  # @return [Integer] captured NPC MP or equipment-aware player MP
  def max_mp
    npc? ? npc_combat_data["max_mp"].to_i : character&.effective_max_mp.to_i
  end

  def current_mp
    npc? ? metadata.to_h.fetch("current_mp", max_mp).to_i : character&.current_mp.to_i
  end

  # Pure selection rules shared by the HTML projection and locked mutations.
  # Automatic handoff after a defeat does not consume a manual switch.
  def selected_opponent(opponents:)
    living = opponents.select(&:combat_alive?).sort_by(&:id)
    living.find { |opponent| opponent.id == metadata.to_h["selected_target_participation_id"].to_i } || living.first
  end

  def opponent_switches_remaining(opponents:)
    [opponents.size - 1 - metadata.to_h["opponent_switches_used"].to_i, 0].max
  end

  # The template is editable content; a started fight retains its own captured
  # attributes, equipment and presentation, including per-roster overrides.
  # Equipment is descriptive NPC content, not player-owned inventory or loot.
  def snapshot_npc_combat_data!
    return unless npc? && !metadata.to_h.key?("npc_combat_data")

    update!(metadata: metadata.to_h.merge("npc_combat_data" => npc_combat_data))
  end

  def npc_combat_data
    return {} unless npc?
    return metadata["npc_combat_data"] if metadata.to_h.key?("npc_combat_data")

    keys = %w[stats display_stats equipment avatar_image max_mp combat_profile max_attacks_per_turn response_attack_counts response_block_keys search_enabled search_max_level_difference]
    template_data = npc_template.metadata.to_h
    level_data = template_data.fetch("level_profiles", {}).fetch(participant_level.to_s, {})
    data = template_data.slice(*keys).deep_merge(level_data.slice(*keys)).deep_merge(metadata.to_h.slice(*keys))
    # A captured loadout is a complete slot set. In particular, an empty or
    # smaller level/member set must not retain equipment from the base setup.
    equipment_owner = [metadata.to_h, level_data, template_data].find { |layer| layer.key?("equipment") }
    data["equipment"] = equipment_owner["equipment"] if equipment_owner
    data["stats"] = npc_template.combat_stats.stringify_keys.merge(data.fetch("stats", {}))
    data
  end

  private

  def npc_content_validity
    return unless npc?

    NpcTemplate.combat_content_errors(metadata.to_h).each { |message| errors.add(:metadata, message) }
    if metadata.to_h.key?("npc_combat_data")
      NpcTemplate.combat_content_errors(metadata["npc_combat_data"]).each { |message| errors.add(:metadata, message) }
    end
  end

  def has_character_or_npc
    if character_id.blank? && npc_template_id.blank?
      errors.add(:base, "must have either a character or an NPC template")
    end
    if character_id.present? && npc_template_id.present?
      errors.add(:base, "cannot have both a character and an NPC template")
    end
  end
end
