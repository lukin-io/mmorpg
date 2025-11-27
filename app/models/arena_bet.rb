# frozen_string_literal: true

# Represents a wager on an arena match outcome.
#
# Players can bet gold on which combatant will win.
# Winnings are distributed based on the betting pool.
#
# @example Place a bet
#   bet = ArenaBet.create!(
#     user: current_user,
#     arena_match: match,
#     predicted_winner: character,
#     amount: 100,
#     currency_type: :gold
#   )
#
class ArenaBet < ApplicationRecord
  CURRENCY_TYPES = {gold: 0, silver: 1}.freeze
  MIN_BET = 10
  MAX_BET = 10_000

  enum :currency_type, CURRENCY_TYPES
  enum :status, {pending: 0, won: 1, lost: 2, refunded: 3}

  belongs_to :user
  belongs_to :arena_match
  belongs_to :predicted_winner, class_name: "Character"

  validates :amount, numericality: {greater_than_or_equal_to: MIN_BET, less_than_or_equal_to: MAX_BET}
  validates :user_id, uniqueness: {scope: :arena_match_id, message: "can only place one bet per match"}

  validate :match_accepts_bets, on: :create
  validate :user_has_funds, on: :create
  validate :not_betting_on_self, on: :create

  before_create :deduct_funds
  after_create :broadcast_pool_update

  scope :for_match, ->(match) { where(arena_match: match) }
  scope :for_character, ->(char) { where(predicted_winner: char) }

  # Calculate total pool for a match
  def self.total_pool(match)
    for_match(match).sum(:amount)
  end

  # Calculate pool for a specific character
  def self.pool_for_character(match, character)
    for_match(match).for_character(character).sum(:amount)
  end

  # Calculate odds for a character (returns multiplier)
  def self.odds_for(match, character)
    total = total_pool(match)
    return 2.0 if total.zero?

    char_pool = pool_for_character(match, character)
    return 2.0 if char_pool.zero?

    (total.to_f / char_pool).round(2)
  end

  # Calculate potential winnings
  def potential_winnings
    odds = self.class.odds_for(arena_match, predicted_winner)
    (amount * odds * 0.95).to_i # 5% house rake
  end

  # Resolve bet after match ends
  def resolve!(winner)
    if predicted_winner == winner
      payout = potential_winnings
      user.increment!(currency_type, payout)
      update!(status: :won, payout_amount: payout)
    else
      update!(status: :lost, payout_amount: 0)
    end
  end

  # Refund bet (if match is cancelled)
  def refund!
    user.increment!(currency_type, amount)
    update!(status: :refunded, payout_amount: amount)
  end

  private

  def match_accepts_bets
    return if arena_match&.pending? || arena_match&.queued?

    errors.add(:arena_match, "is not accepting bets")
  end

  def user_has_funds
    balance = currency_type == "gold" ? user.character&.gold : user.character&.silver
    return if balance.to_i >= amount

    errors.add(:amount, "exceeds available funds")
  end

  def not_betting_on_self
    return unless arena_match

    participant_ids = arena_match.arena_participations.pluck(:character_id)
    return unless participant_ids.include?(user.character&.id)

    errors.add(:base, "cannot bet on a match you're participating in")
  end

  def deduct_funds
    if currency_type == "gold"
      user.character.decrement!(:gold, amount)
    else
      user.character.decrement!(:silver, amount)
    end
  end

  def broadcast_pool_update
    ActionCable.server.broadcast(
      "arena_match:#{arena_match_id}:bets",
      {
        type: "pool_update",
        total_pool: self.class.total_pool(arena_match),
        odds: arena_match.arena_participations.map do |p|
          {character_id: p.character_id, odds: self.class.odds_for(arena_match, p.character)}
        end
      }
    )
  end
end
