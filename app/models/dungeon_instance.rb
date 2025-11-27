# frozen_string_literal: true

# Represents an instanced dungeon run for a party.
#
# Each party gets their own instance of the dungeon that persists
# until completed, failed, or expired.
#
# @example Create a dungeon instance
#   instance = DungeonInstance.create!(
#     dungeon_template: template,
#     party: party,
#     difficulty: :normal
#   )
#   instance.start!
#
class DungeonInstance < ApplicationRecord
  DIFFICULTIES = {easy: 0, normal: 1, hard: 2, nightmare: 3}.freeze
  INSTANCE_DURATION_HOURS = 2

  enum :difficulty, DIFFICULTIES
  enum :status, {pending: 0, active: 1, completed: 2, failed: 3, expired: 4}

  belongs_to :dungeon_template
  belongs_to :party
  belongs_to :leader, class_name: "Character"

  has_many :dungeon_progress_checkpoints, dependent: :destroy
  has_many :dungeon_encounters, dependent: :destroy

  validates :difficulty, presence: true
  validates :instance_key, uniqueness: true

  before_create :generate_instance_key
  before_create :set_expiration

  scope :active_for_party, ->(party) { where(party: party, status: :active) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  # Start the dungeon instance
  def start!
    return false unless pending?

    transaction do
      update!(status: :active, started_at: Time.current)
      generate_encounters!
      create_initial_checkpoint!
    end
    true
  end

  # Progress to next encounter
  def advance_to_encounter!(encounter)
    return false unless active?
    return false if encounter.dungeon_instance != self

    update!(current_encounter_index: encounter.encounter_index)
    encounter.start!
  end

  # Complete an encounter
  def complete_encounter!(encounter, success:)
    return false unless active?

    if success
      encounter.update!(status: :completed, completed_at: Time.current)
      grant_encounter_rewards!(encounter)

      if final_encounter?(encounter)
        complete_dungeon!
      else
        create_checkpoint!(encounter)
      end
    else
      handle_party_wipe!(encounter)
    end
  end

  # Complete the entire dungeon
  def complete_dungeon!
    update!(
      status: :completed,
      completed_at: Time.current,
      completion_time_seconds: (Time.current - started_at).to_i
    )
    grant_completion_rewards!
    broadcast_completion!
  end

  # Handle party wipe
  def handle_party_wipe!(encounter)
    remaining_attempts = attempts_remaining - 1

    if remaining_attempts <= 0
      update!(status: :failed, completed_at: Time.current)
    else
      update!(attempts_remaining: remaining_attempts)
      respawn_at_checkpoint!
    end
  end

  # Check if dungeon is expired
  def expired?
    expires_at.present? && Time.current > expires_at
  end

  # Get current encounter
  def current_encounter
    dungeon_encounters.find_by(encounter_index: current_encounter_index)
  end

  # Get next encounter
  def next_encounter
    dungeon_encounters.find_by(encounter_index: current_encounter_index + 1)
  end

  # Check if this is the final boss
  def final_encounter?(encounter)
    encounter.boss? && encounter.encounter_index == dungeon_encounters.count - 1
  end

  private

  def generate_instance_key
    self.instance_key = "#{dungeon_template.slug}-#{SecureRandom.hex(4)}-#{Time.current.to_i}"
  end

  def set_expiration
    self.expires_at = Time.current + INSTANCE_DURATION_HOURS.hours
    self.attempts_remaining = 3
    self.current_encounter_index = 0
  end

  def generate_encounters!
    dungeon_template.encounter_templates.order(:sequence).each_with_index do |template, index|
      dungeon_encounters.create!(
        encounter_template: template,
        encounter_index: index,
        status: :pending,
        difficulty_modifier: difficulty_modifier
      )
    end
  end

  def difficulty_modifier
    case difficulty
    when "easy" then 0.8
    when "normal" then 1.0
    when "hard" then 1.3
    when "nightmare" then 1.8
    else 1.0
    end
  end

  def create_initial_checkpoint!
    dungeon_progress_checkpoints.create!(
      checkpoint_index: 0,
      encounter_index: 0,
      party_state: serialize_party_state
    )
  end

  def create_checkpoint!(after_encounter)
    dungeon_progress_checkpoints.create!(
      checkpoint_index: dungeon_progress_checkpoints.count,
      encounter_index: after_encounter.encounter_index + 1,
      party_state: serialize_party_state
    )
  end

  def serialize_party_state
    party.active_members.includes(:character).map do |membership|
      char = membership.user.character
      {
        character_id: char.id,
        current_hp: char.current_hp,
        current_mp: char.current_mp
      }
    end
  end

  def respawn_at_checkpoint!
    latest = dungeon_progress_checkpoints.order(:checkpoint_index).last
    return unless latest

    # Restore party to checkpoint state
    latest.party_state.each do |state|
      char = Character.find_by(id: state["character_id"])
      next unless char

      char.update!(
        current_hp: state["current_hp"],
        current_mp: state["current_mp"]
      )
    end

    update!(current_encounter_index: latest.encounter_index)
  end

  def grant_encounter_rewards!(encounter)
    xp_per_member = encounter.xp_reward / party.active_members.count
    gold_per_member = encounter.gold_reward / party.active_members.count

    party.active_members.each do |membership|
      char = membership.user.character
      char.gain_experience(xp_per_member)
      char.increment!(:gold, gold_per_member)
    end
  end

  def grant_completion_rewards!
    base_xp = dungeon_template.completion_xp * difficulty_modifier
    base_gold = dungeon_template.completion_gold * difficulty_modifier

    party.active_members.each do |membership|
      char = membership.user.character
      char.gain_experience((base_xp / party.active_members.count).to_i)
      char.increment!(:gold, (base_gold / party.active_members.count).to_i)

      # Roll for loot
      roll_loot_for!(char)
    end
  end

  def roll_loot_for!(character)
    return unless dungeon_template.loot_table.present?

    # 20% chance per item in loot table
    dungeon_template.loot_table.each do |loot_entry|
      next unless rand(100) < 20

      item = ItemTemplate.find_by(item_key: loot_entry["item_key"])
      next unless item

      Game::Inventory::Manager.add_item(character, item, loot_entry.fetch("quantity", 1))
    end
  end

  def broadcast_completion!
    ActionCable.server.broadcast(
      "party:#{party_id}",
      {
        type: "dungeon_complete",
        dungeon_name: dungeon_template.name,
        completion_time: completion_time_seconds,
        difficulty: difficulty
      }
    )
  end
end
