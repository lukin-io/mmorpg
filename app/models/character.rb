# frozen_string_literal: true

class Character < ApplicationRecord
  MAX_NAME_LENGTH = 30

  # Available player avatars (randomly assigned on character creation)
  AVATARS = %w[dwarven nightveil lightbearer pathfinder arcanist ironbound].freeze

  # Base faction alignments (player chooses one)
  ALIGNMENTS = {
    neutral: "neutral",
    alliance: "alliance",
    rebellion: "rebellion"
  }.freeze

  # Alignment score thresholds for tier progression
  # Score ranges: -1000 to +1000
  ALIGNMENT_TIERS = {
    # Negative scores (Dark path)
    absolute_darkness: {range: -1000..-800, emoji: "🖤", name: "Absolute Darkness"},
    true_darkness: {range: -799..-500, emoji: "⬛", name: "True Darkness"},
    child_of_darkness: {range: -499..-200, emoji: "🌑", name: "Child of Darkness"},

    # Neutral zone
    twilight_walker: {range: -199..-50, emoji: "🌘", name: "Twilight Walker"},
    neutral: {range: -49..49, emoji: "☯️", name: "Neutral"},
    dawn_seeker: {range: 50..199, emoji: "🌒", name: "Dawn Seeker"},

    # Positive scores (Light path)
    child_of_light: {range: 200..499, emoji: "🌕", name: "Child of Light"},
    true_light: {range: 500..799, emoji: "✨", name: "True Light"},
    celestial: {range: 800..1000, emoji: "👼", name: "Celestial"}
  }.freeze

  # Chaos alignment (separate axis, based on karma/actions)
  CHAOS_TIERS = {
    lawful: {range: 0..199, emoji: "⚖️", name: "Lawful"},
    balanced: {range: 200..499, emoji: "🔄", name: "Balanced"},
    chaotic: {range: 500..799, emoji: "🔥", name: "Chaotic"},
    absolute_chaos: {range: 800..1000, emoji: "💥", name: "Absolute Chaos"}
  }.freeze

  belongs_to :user
  belongs_to :character_class, optional: true
  belongs_to :guild, optional: true
  belongs_to :clan, optional: true
  belongs_to :secondary_specialization, class_name: "ClassSpecialization", optional: true

  has_one :position, class_name: "CharacterPosition", dependent: :destroy
  has_one :inventory, dependent: :destroy
  has_many :arena_rankings, dependent: :destroy
  has_one :arena_ranking, -> { where(ladder_type: "arena") }, class_name: "ArenaRanking", dependent: :destroy
  has_many :arena_applications, foreign_key: :applicant_id, dependent: :destroy
  has_many :arena_participations, dependent: :destroy

  has_many :character_skills, dependent: :destroy
  has_many :skill_nodes, through: :character_skills
  has_many :profession_progresses, dependent: :destroy
  has_many :profession_tools, dependent: :destroy
  has_many :battle_participants, dependent: :destroy
  has_many :battles, through: :battle_participants
  has_many :initiated_battles, class_name: "Battle", foreign_key: :initiator_id, dependent: :nullify
  has_many :quest_assignments, dependent: :destroy
  has_many :movement_commands, dependent: :destroy
  has_many :moderation_tickets_as_subject,
    class_name: "Moderation::Ticket",
    foreign_key: :subject_character_id,
    dependent: :nullify

  validates :name, presence: true, uniqueness: true, length: {maximum: MAX_NAME_LENGTH}
  validates :level, numericality: {greater_than: 0}
  validates :experience, numericality: {greater_than_or_equal_to: 0}
  validates :stat_points_available, :skill_points_available, numericality: {greater_than_or_equal_to: 0}
  validates :reputation, numericality: {greater_than_or_equal_to: 0}
  validates :alignment_score, numericality: true
  validates :faction_alignment, inclusion: {in: ALIGNMENTS.values}

  validate :respect_character_limit, on: :create

  before_validation :inherit_memberships, on: :create
  before_validation :assign_random_avatar, on: :create
  after_create :ensure_inventory!
  after_create_commit :ensure_tutorial_assignments

  def stats
    base = (character_class&.base_stats || {}).transform_keys(&:to_sym)
    allocated_stats.each do |stat, value|
      key = stat.to_sym
      base[key] = base.fetch(key, 0) + value.to_i
    end
    Game::Systems::StatBlock.new(base:)
  end

  # Calculate maximum action points for combat
  # Formula: Base AP (50) + (Level × 3) + (Agility × 2)
  # This determines how many attacks/blocks a character can perform per turn
  #
  # @return [Integer] the character's maximum action points
  def max_action_points
    base_ap = 50
    level_bonus = level * 3
    agility_bonus = stats.get(:agility).to_i * 2

    base_ap + level_bonus + agility_bonus
  end

  # Get current alignment tier based on alignment_score
  def alignment_tier
    score = alignment_score.to_i.clamp(-1000, 1000)
    ALIGNMENT_TIERS.find { |_, data| data[:range].include?(score) }&.first || :neutral
  end

  # Get alignment tier data (emoji, name)
  def alignment_tier_data
    ALIGNMENT_TIERS[alignment_tier] || ALIGNMENT_TIERS[:neutral]
  end

  # Get alignment emoji icon
  def alignment_emoji
    alignment_tier_data[:emoji]
  end

  # Get alignment tier display name
  def alignment_tier_name
    alignment_tier_data[:name]
  end

  # Get chaos tier based on chaos_score (defaults to 0 if not set)
  def chaos_tier
    score = (chaos_score || 0).to_i.clamp(0, 1000)
    CHAOS_TIERS.find { |_, data| data[:range].include?(score) }&.first || :lawful
  end

  # Get chaos tier data
  def chaos_tier_data
    CHAOS_TIERS[chaos_tier] || CHAOS_TIERS[:lawful]
  end

  # Get chaos emoji
  def chaos_emoji
    chaos_tier_data[:emoji]
  end

  # Get faction emoji based on faction_alignment
  def faction_emoji
    case faction_alignment
    when "alliance" then "🛡️"
    when "rebellion" then "⚔️"
    else "🏳️"
    end
  end

  # Full alignment display with emojis
  def alignment_display
    "#{faction_emoji} #{alignment_emoji} #{alignment_tier_name}"
  end

  # Adjust alignment score (clamped to valid range)
  def adjust_alignment!(delta)
    new_score = (alignment_score + delta).clamp(-1000, 1000)
    update!(alignment_score: new_score)
  end

  # Adjust chaos score
  def adjust_chaos!(delta)
    new_score = ((chaos_score || 0) + delta).clamp(0, 1000)
    update!(chaos_score: new_score)
  end

  # ===================
  # Passive Skills
  # ===================

  # Get the level of a passive skill
  #
  # @param skill_key [Symbol, String] the skill identifier (e.g., :wanderer)
  # @return [Integer] skill level (0-100, defaults to 0)
  def passive_skill_level(skill_key)
    (passive_skills[skill_key.to_s] || 0).to_i
  end

  # Set the level of a passive skill
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @param level [Integer] new level (clamped to 0-max_level)
  def set_passive_skill!(skill_key, level)
    key = skill_key.to_s
    max = Game::Skills::PassiveSkillRegistry.max_level(key)
    clamped = level.to_i.clamp(0, max)

    new_skills = passive_skills.merge(key => clamped)
    update!(passive_skills: new_skills)
  end

  # Increase a passive skill by a given amount
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @param amount [Integer] amount to increase (default 1)
  def increase_passive_skill!(skill_key, amount = 1)
    current = passive_skill_level(skill_key)
    set_passive_skill!(skill_key, current + amount)
  end

  # Get a calculator for all passive skill effects
  #
  # @return [Game::Skills::PassiveSkillCalculator]
  def passive_skill_calculator
    @passive_skill_calculator ||= Game::Skills::PassiveSkillCalculator.new(self)
  end

  # Clear the cached calculator (call after skill changes)
  def clear_passive_skill_cache!
    @passive_skill_calculator = nil
  end

  # Get full asset path for character avatar image
  #
  # @return [String] full asset path (e.g., "avatars/dwarven.png")
  def avatar_image_path
    avatar_name = avatar.presence || AVATARS.first
    "avatars/#{avatar_name}.png"
  end

  private

  def inherit_memberships
    return unless user

    self.guild ||= user.primary_guild
    self.clan ||= user.primary_clan
  end

  def respect_character_limit
    return unless user

    if user.characters.count >= User::MAX_CHARACTERS
      errors.add(:base, "character limit reached")
    end
  end

  def ensure_inventory!
    create_inventory!(slot_capacity: 30, weight_capacity: 100) unless inventory
  end

  def ensure_tutorial_assignments
    Game::Quests::TutorialBootstrapper.new(character: self).call
  rescue ActiveRecord::RecordNotFound
    true
  end

  def assign_random_avatar
    return if avatar.present?

    self.avatar = AVATARS.sample
  end
end
