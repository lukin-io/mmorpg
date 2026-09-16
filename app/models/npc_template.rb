# frozen_string_literal: true

# NpcTemplate is the central model for all NPC definitions in the game.
# It stores source-backed combat NPC definitions.
#
# Metadata stores combat, loot, image, and spawn data captured from Neverlands.
#
# Usage:
#   # Outside world hostile NPC
#   rat = NpcTemplate.find_by(npc_key: "plague_rat")
#   rat.hostile?           # => true
#   rat.combat_stats       # => { attack: 15, defense: 8, hp: 100, ... }
#
#   # Arena training bot
#   bot = NpcTemplate.find_by(npc_key: "arena_training_dummy")
#   bot.arena_bot?          # => true
#   bot.combat_behavior     # => :passive
#
class NpcTemplate < ApplicationRecord
  include Npc::CombatStats
  include Npc::Combatable

  ROLES = %w[hostile arena_bot].freeze
  DISPLAY_STAT_KEYS = %w[strength dexterity luck knowledge wisdom armor_class evasion accuracy crushing endurance armor_penetration].freeze
  EQUIPMENT_ARTWORK_KEYS = %w[
    orc_dagger orc_boots orc_bracers orc_belt
    goblin_stick goblin_sandals goblin_gloves goblin_chainmail
    bandit_headband bandit_amulet bandit_sword bandit_boots bandit_ring
    bandit_bracers bandit_gloves bandit_dagger bandit_jacket bandit_belt
    robber_helmet robber_talisman robber_club robber_armor
    ogre_helmet ogre_amulet ogre_club ogre_boots ogre_ring
    ogre_bracers ogre_gloves ogre_armor ogre_belt
  ].freeze

  has_many :tile_npcs, dependent: :restrict_with_error
  has_many :arena_applications, dependent: :restrict_with_error
  has_many :arena_participations, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :npc_key, uniqueness: true, allow_blank: true
  validates :level, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :role, presence: true, inclusion: {in: ROLES}
  validates :dialogue, presence: true
  validate :referenced_key_must_remain_stable
  validate :combat_content_validity
  before_destroy :restrict_roster_reference_deletion, prepend: true

  # Scope to find NPCs by role
  scope :with_role, ->(role) { where(role: role) }

  # Scope for hostile NPCs only
  scope :hostile, -> { where(role: "hostile") }

  # Scope for arena bot NPCs
  scope :arena_bots, -> { where(role: "arena_bot") }

  def description
    metadata&.dig("description")
  end

  # Get NPC's passive skill level when explicitly captured in metadata.
  #
  # @param skill_key [Symbol, String] the skill identifier (e.g., :knife_mastery)
  # @return [Integer] skill level (0-100, defaults to 0)
  def passive_skill_level(skill_key)
    key = skill_key.to_s
    skills = metadata&.dig("passive_skills")
    return 0 unless skills

    (skills[key] || skills[skill_key.to_sym]).to_i
  end

  # Get all passive skills for this NPC
  #
  # @return [Hash] skill_key => level
  def passive_skills
    metadata&.dig("passive_skills") || {}
  end

  def health
    max_hp
  end

  # Check if NPC is an arena bot
  def arena_bot?
    role == "arena_bot"
  end

  def ai_behavior
    combat_behavior.to_s
  end

  # Get arena rooms this NPC can appear in
  #
  # @return [Array<String>] array of room slugs
  def arena_rooms
    metadata&.dig("arena_rooms") || []
  end

  def respawn_seconds
    configured_respawn_seconds
  end

  def configured_respawn_seconds
    positive_metadata_integer("respawn_seconds") ||
      positive_metadata_integer("spawn_respawn_seconds")
  end

  def respawn_variance_seconds
    metadata_integer("respawn_variance_seconds") ||
      metadata_integer("spawn_respawn_variance_seconds")
  end

  def avatar_emoji
    metadata&.dig("avatar").presence
  end

  private

  def combat_content_validity
    self.class.combat_content_errors(metadata).each { |message| errors.add(:metadata, message) }
  end

  public

  # Content validation is reused for per-roster overrides at participation
  # creation. Visible totals remain explicit: an item name or portrait never
  # supplies an invented stat, damage range, drop or inventory grant.
  def self.combat_content_errors(data, allow_levels: true)
    return ["must be an object"] unless data.is_a?(Hash)

    messages = []
    if data.key?("search_enabled") && ![true, false].include?(data["search_enabled"])
      messages << "search_enabled must be boolean"
    end
    if data.key?("search_max_level_difference") && !(data["search_max_level_difference"].is_a?(Integer) && data["search_max_level_difference"].between?(0, 100))
      messages << "search_max_level_difference must be a bounded non-negative integer"
    end
    if data.key?("response_attack_counts")
      counts = data["response_attack_counts"]
      unless counts.is_a?(Array) && counts.any? && counts.size <= 4 && counts.all? { |count| count.is_a?(Integer) && count.between?(1, 4) }
        messages << "response_attack_counts must contain one to four bounded attack counts"
      end
    end
    if data.key?("response_block_keys")
      keys = data["response_block_keys"]
      unless keys.is_a?(Array) && keys.size <= 10 && (keys - Game::Combat::ActionCatalog::STANDARD_BLOCKS.values.pluck(:key)).empty?
        messages << "response_block_keys must contain known physical blocks"
      end
    end
    if data.key?("level_profiles")
      profiles = data["level_profiles"]
      if !allow_levels || !profiles.is_a?(Hash) || profiles.size > 100 || profiles.keys.any? { |level| !level.to_s.match?(/\A\d{1,3}\z/) }
        messages << "level_profiles must use explicit numeric levels"
      else
        profiles.each_value do |profile|
          messages.concat(combat_content_errors(profile, allow_levels: false))
        end
      end
    end
    %w[stats display_stats].each do |key|
      next unless data.key?(key)

      values = data[key]
      unless values.is_a?(Hash) && values.values.all? { |value| value.is_a?(Integer) && value.abs <= 1_000_000 }
        messages << "#{key} must contain bounded integer values"
      end
      if key == "display_stats" && values.is_a?(Hash) && (values.keys - DISPLAY_STAT_KEYS).any?
        messages << "display_stats contains an unsupported attribute"
      end
    end
    if data.key?("max_mp") && !(data["max_mp"].is_a?(Integer) && data["max_mp"].between?(0, 1_000_000))
      messages << "max_mp must be a non-negative integer"
    end
    if data.key?("avatar_image") && !data["avatar_image"].to_s.match?(/\A[a-z0-9_-]+\.png\z/)
      messages << "avatar_image must be a local NPC image filename"
    end
    if data.key?("equipment")
      equipment = data["equipment"]
      if !equipment.is_a?(Hash) || (equipment.keys - EquipmentSlots::KEYS).any?
        messages << "equipment must use known paper-doll slots"
      else
        equipment.each_value do |item|
          unless item.is_a?(Hash) && item["name"].is_a?(String) && item["name"].strip.length.between?(1, 120)
            messages << "equipment must name each item"
            next
          end
          if item.key?("artwork") && !EQUIPMENT_ARTWORK_KEYS.include?(item["artwork"])
            messages << "equipment artwork is unavailable"
          end
          if item.key?("properties") && !(item["properties"].is_a?(Array) && item["properties"].size <= 20 && item["properties"].all? { |value| value.is_a?(String) && value.length <= 120 })
            messages << "equipment properties must be a bounded list of text"
          end
        end
      end
    end
    messages
  end

  private

  # Lock the template before checking JSON roster references. Roster writes
  # take key-share locks on their templates, so either the reference commits
  # first and prevents retirement, or retirement completes and the writer
  # rejects the missing key. Inactive anchors retain these dependencies.
  def referenced_key_must_remain_stable
    return unless persisted? && will_save_change_to_npc_key?

    current_key = self.class.where(id:).lock.pick(:npc_key)
    if tile_npcs.exists? || roster_reference_exists?(current_key)
      errors.add(:npc_key, "cannot change while referenced by cell encounters")
    end
  end

  def restrict_roster_reference_deletion
    current_key = self.class.where(id:).lock.pick(:npc_key)
    return unless roster_reference_exists?(current_key)

    errors.add(:base, "Cannot delete an NPC template referenced by cell encounter rosters")
    throw(:abort)
  end

  def roster_reference_exists?(key)
    return false if key.blank?

    reference = {"encounter_rosters" => [{"members" => [{"npc_key" => key}]}]}
    TileNpc.where("metadata @> ?::jsonb", reference.to_json).exists?
  end

  def positive_metadata_integer(key)
    value = metadata_integer(key)
    value if value&.positive?
  end

  def metadata_integer(key)
    value = metadata&.dig(key)
    return if value.blank?

    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end
end
