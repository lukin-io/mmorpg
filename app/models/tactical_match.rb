# frozen_string_literal: true

# Represents a tactical grid-based arena match.
#
# Uses a 2D grid where characters have positions and can move/attack.
# Turn-based combat with action points per turn.
#
# @example Create a tactical match
#   match = TacticalMatch.create!(creator: char1, grid_size: 8)
#   match.add_opponent!(char2)
#   match.start!
#
class TacticalMatch < ApplicationRecord
  GRID_SIZES = [6, 8, 10].freeze
  ACTIONS_PER_TURN = 3
  DEFAULT_TURN_TIME = 60

  enum :status, {
    pending: 0,
    active: 1,
    completed: 2,
    cancelled: 3,
    forfeited: 4
  }

  belongs_to :creator, class_name: "Character"
  belongs_to :opponent, class_name: "Character", optional: true
  belongs_to :winner, class_name: "Character", optional: true
  belongs_to :arena_room, optional: true

  has_many :tactical_participants, dependent: :destroy
  has_many :tactical_combat_log_entries, dependent: :destroy

  validates :grid_size, inclusion: {in: GRID_SIZES}
  validates :turn_time_limit, numericality: {greater_than: 0, less_than_or_equal_to: 300}

  scope :recent, -> { order(created_at: :desc).limit(20) }
  scope :active_matches, -> { where(status: :active) }

  # Initialize the grid with starting positions
  def initialize_grid!
    self.grid_state = build_initial_grid
    self.current_turn_character_id = creator_id
    self.turn_number = 1
    self.actions_remaining = ACTIONS_PER_TURN
    save!
  end

  # Add an opponent and start the match
  def add_opponent!(character)
    return false if opponent.present?
    return false if character == creator

    transaction do
      update!(opponent: character, status: :active)
      place_characters_on_grid!
      create_participants!
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Get character position on grid
  def character_position(character)
    participant = tactical_participants.find_by(character: character)
    return nil unless participant

    {x: participant.grid_x, y: participant.grid_y}
  end

  # Move character on grid
  def move_character!(character, new_x, new_y)
    participant = tactical_participants.find_by(character: character)
    return false unless participant
    return false unless valid_move?(participant, new_x, new_y)

    participant.update!(grid_x: new_x, grid_y: new_y)
    consume_action!
    true
  end

  # Current turn character
  def current_turn_character
    Character.find_by(id: current_turn_character_id)
  end

  # Advance to next turn
  def advance_turn!
    next_character = (current_turn_character == creator) ? opponent : creator
    update!(
      current_turn_character_id: next_character.id,
      turn_number: turn_number + 1,
      actions_remaining: ACTIONS_PER_TURN,
      turn_started_at: Time.current
    )
  end

  # Consume an action point
  def consume_action!
    new_actions = actions_remaining - 1
    update!(actions_remaining: new_actions)
    advance_turn! if new_actions <= 0
  end

  # Check if a position is valid for movement
  def valid_move?(participant, new_x, new_y)
    return false if new_x.negative? || new_y.negative?
    return false if new_x >= grid_size || new_y >= grid_size
    return false if tile_occupied?(new_x, new_y)

    # Check movement range (typically 1-3 tiles)
    distance = (participant.grid_x - new_x).abs + (participant.grid_y - new_y).abs
    distance <= participant.movement_range
  end

  # Check if tile is occupied
  def tile_occupied?(x, y)
    tactical_participants.exists?(grid_x: x, grid_y: y, alive: true)
  end

  # Get participant at position
  def participant_at(x, y)
    tactical_participants.find_by(grid_x: x, grid_y: y, alive: true)
  end

  # Check if characters are adjacent
  def adjacent?(char1, char2)
    pos1 = character_position(char1)
    pos2 = character_position(char2)
    return false unless pos1 && pos2

    distance = (pos1[:x] - pos2[:x]).abs + (pos1[:y] - pos2[:y]).abs
    distance == 1
  end

  # End match with winner
  def declare_winner!(winning_character)
    update!(
      status: :completed,
      winner: winning_character,
      ended_at: Time.current
    )
    distribute_rewards!
  end

  # Forfeit match
  def forfeit!(forfeiting_character)
    winner_char = (forfeiting_character == creator) ? opponent : creator
    update!(
      status: :forfeited,
      winner: winner_char,
      ended_at: Time.current
    )
  end

  private

  def build_initial_grid
    grid = Array.new(grid_size) { Array.new(grid_size, nil) }

    # Add terrain features
    add_terrain_features!(grid)

    grid
  end

  def add_terrain_features!(grid)
    # Add some obstacles/cover
    obstacles = grid_size / 2
    obstacles.times do
      x = rand(1..grid_size - 2)
      y = rand(1..grid_size - 2)
      grid[y][x] = {type: "obstacle", passable: false}
    end

    # Add cover positions
    (obstacles / 2).times do
      x = rand(1..grid_size - 2)
      y = rand(1..grid_size - 2)
      grid[y][x] = {type: "cover", passable: true, defense_bonus: 20} unless grid[y][x]
    end
  end

  def place_characters_on_grid!
    # Creator starts at bottom
    tactical_participants.create!(
      character: creator,
      grid_x: grid_size / 2,
      grid_y: 0,
      current_hp: creator.max_hp,
      current_mp: creator.max_mp,
      movement_range: 3,
      attack_range: 1,
      alive: true
    )

    # Opponent starts at top
    tactical_participants.create!(
      character: opponent,
      grid_x: grid_size / 2,
      grid_y: grid_size - 1,
      current_hp: opponent.max_hp,
      current_mp: opponent.max_mp,
      movement_range: 3,
      attack_range: 1,
      alive: true
    )
  end

  def create_participants!
    # Already done in place_characters_on_grid!
  end

  def distribute_rewards!
    return unless winner

    # Grant XP and gold to winner
    winner.gain_experience(100 * turn_number)
    winner.increment!(:gold, 50)

    # Smaller consolation for loser
    loser = (winner == creator) ? opponent : creator
    loser.gain_experience(25 * turn_number)
  end
end
