# frozen_string_literal: true

module Arena
  # Distributes rewards to arena match participants based on outcome
  # Handles XP, gold, rating, and item rewards
  #
  # @example Distribute rewards after match
  #   Arena::RewardsDistributor.new(match).distribute!
  #
  # @example Calculate rewards preview
  #   rewards = Arena::RewardsDistributor.new(match).calculate_rewards(character)
  #
  class RewardsDistributor
    # Base reward configurations
    REWARD_CONFIG = {
      duel: {
        winner_xp_base: 50,
        winner_gold_base: 25,
        winner_rating_base: 15,
        loser_xp_base: 20,
        loser_gold_base: 5,
        loser_rating_base: -10,
        item_drop_chance: 0.15
      },
      skirmish: {
        winner_xp_base: 75,
        winner_gold_base: 40,
        winner_rating_base: 20,
        loser_xp_base: 30,
        loser_gold_base: 10,
        loser_rating_base: -15,
        item_drop_chance: 0.20
      },
      tournament: {
        winner_xp_base: 150,
        winner_gold_base: 100,
        winner_rating_base: 50,
        loser_xp_base: 50,
        loser_gold_base: 20,
        loser_rating_base: -25,
        item_drop_chance: 0.35
      },
      group: {
        winner_xp_base: 100,
        winner_gold_base: 60,
        winner_rating_base: 25,
        loser_xp_base: 40,
        loser_gold_base: 15,
        loser_rating_base: -15,
        item_drop_chance: 0.25
      },
      sacrifice: {
        winner_xp_base: 200,
        winner_gold_base: 150,
        winner_rating_base: 40,
        loser_xp_base: 0,
        loser_gold_base: 0,
        loser_rating_base: -50,
        item_drop_chance: 0.50
      }
    }.freeze

    # Item pools by tier (based on character level)
    ITEM_POOLS = {
      tier1: { # Levels 1-10
        common: %w[arena_bandage arena_potion_small arena_scroll_minor],
        uncommon: %w[arena_ring_bronze arena_amulet_bronze],
        rare: %w[arena_weapon_tier1 arena_armor_tier1]
      },
      tier2: { # Levels 11-25
        common: %w[arena_bandage_improved arena_potion_medium arena_scroll_standard],
        uncommon: %w[arena_ring_silver arena_amulet_silver arena_trinket_tier2],
        rare: %w[arena_weapon_tier2 arena_armor_tier2]
      },
      tier3: { # Levels 26-50
        common: %w[arena_bandage_advanced arena_potion_large arena_scroll_greater],
        uncommon: %w[arena_ring_gold arena_amulet_gold arena_trinket_tier3],
        rare: %w[arena_weapon_tier3 arena_armor_tier3],
        epic: %w[arena_legendary_fragment]
      },
      tier4: { # Levels 51+
        common: %w[arena_elixir arena_potion_supreme arena_scroll_master],
        uncommon: %w[arena_ring_platinum arena_amulet_platinum arena_trinket_tier4],
        rare: %w[arena_weapon_tier4 arena_armor_tier4],
        epic: %w[arena_legendary_item arena_unique_material]
      }
    }.freeze

    attr_reader :match, :errors

    def initialize(match)
      @match = match
      @errors = []
    end

    # Distribute all rewards to participants
    #
    # @return [Boolean] true if all rewards distributed successfully
    def distribute!
      return false unless match.completed?

      ActiveRecord::Base.transaction do
        match.arena_participations.includes(:character).each do |participation|
          distribute_to_participant(participation)
        end

        match.update!(rewards_distributed_at: Time.current)
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      errors << e.message
      false
    end

    # Calculate potential rewards for a character (preview)
    #
    # @param character [Character] the character
    # @param is_winner [Boolean] whether they won
    # @return [Hash] reward breakdown
    def calculate_rewards(character, is_winner:)
      config = reward_config
      level_multiplier = calculate_level_multiplier(character)

      rewards = {
        xp: 0,
        gold: 0,
        rating_change: 0,
        potential_items: []
      }

      if is_winner
        rewards[:xp] = (config[:winner_xp_base] * level_multiplier).round
        rewards[:gold] = (config[:winner_gold_base] * level_multiplier).round
        rewards[:rating_change] = config[:winner_rating_base]
        rewards[:potential_items] = potential_items_for_tier(character.level)
      else
        rewards[:xp] = (config[:loser_xp_base] * level_multiplier).round
        rewards[:gold] = (config[:loser_gold_base] * level_multiplier).round
        rewards[:rating_change] = config[:loser_rating_base]
      end

      # Apply trauma penalty
      if match.arena_applications.first&.trauma_percent
        trauma = match.arena_applications.first.trauma_percent
        if !is_winner && trauma > 0
          rewards[:trauma_penalty] = trauma
        end
      end

      rewards
    end

    private

    def distribute_to_participant(participation)
      character = participation.character
      is_winner = participation.winner?

      rewards = calculate_rewards(character, is_winner: is_winner)

      # Award XP
      if rewards[:xp] > 0
        character.gain_experience!(rewards[:xp], source: "Arena: #{match.match_type.titleize}")
      end

      # Award gold
      if rewards[:gold] > 0
        character.add_currency!(:gold, rewards[:gold], source: "Arena victory")
      end

      # Update arena rating
      update_arena_rating(character, rewards[:rating_change])

      # Roll for item drop (winners only)
      if is_winner && should_drop_item?
        item_key = roll_item_drop(character.level)
        award_item(character, item_key) if item_key
      end

      # Apply trauma penalty
      if !is_winner && rewards[:trauma_penalty].to_i > 0
        apply_trauma(character, rewards[:trauma_penalty])
      end

      # Record rewards given
      participation.update!(
        rewards_given: {
          xp: rewards[:xp],
          gold: rewards[:gold],
          rating_change: rewards[:rating_change],
          item: @last_awarded_item
        }
      )
    end

    def reward_config
      REWARD_CONFIG[match.match_type.to_sym] || REWARD_CONFIG[:duel]
    end

    def calculate_level_multiplier(character)
      # Scale rewards with level
      base = 1.0 + (character.level.to_f / 100)

      # Bonus for fighting higher level opponents
      opponent_avg_level = match.arena_participations
        .where.not(character: character)
        .joins(:character)
        .average("characters.level").to_f

      if opponent_avg_level > character.level
        base += (opponent_avg_level - character.level) * 0.02
      end

      [base, 3.0].min # Cap at 3x multiplier
    end

    def should_drop_item?
      config = reward_config
      rand < config[:item_drop_chance]
    end

    def roll_item_drop(level)
      tier = item_tier_for_level(level)
      pool = ITEM_POOLS[tier]
      return nil if pool.nil?

      # Weight rarities
      rarity = weighted_rarity_roll
      items = pool[rarity]

      return nil if items.nil? || items.empty?

      items.sample
    end

    def item_tier_for_level(level)
      case level
      when 0..10 then :tier1
      when 11..25 then :tier2
      when 26..50 then :tier3
      else :tier4
      end
    end

    def weighted_rarity_roll
      roll = rand(100)
      case roll
      when 0..2 then :epic     # 3%
      when 3..12 then :rare    # 10%
      when 13..37 then :uncommon # 25%
      else :common              # 62%
      end
    end

    def potential_items_for_tier(level)
      tier = item_tier_for_level(level)
      pool = ITEM_POOLS[tier] || {}
      pool.values.flatten
    end

    def award_item(character, item_key)
      item_template = ItemTemplate.find_by(key: item_key)
      return unless item_template

      item = character.inventory.add_item!(
        item_template,
        source: "Arena Reward",
        metadata: {match_id: match.id}
      )

      @last_awarded_item = item_key

      # Broadcast special item reward
      if item_template.rarity.in?(%w[rare epic legendary])
        ActionCable.server.broadcast(
          match.broadcast_channel,
          {
            type: "item_reward",
            character_name: character.name,
            item_name: item_template.name,
            item_rarity: item_template.rarity
          }
        )
      end

      item
    rescue => e
      Rails.logger.error("Failed to award arena item: #{e.message}")
      nil
    end

    def update_arena_rating(character, change)
      return if change.zero?

      current_rating = character.arena_rating || 1000
      new_rating = [current_rating + change, 0].max

      character.update!(arena_rating: new_rating)

      # Track rating history
      character.arena_rating_history ||= []
      character.arena_rating_history << {
        timestamp: Time.current.iso8601,
        change: change,
        new_rating: new_rating,
        match_id: match.id
      }
      character.save!
    end

    def apply_trauma(character, percent)
      # Trauma - temporary stat reduction
      trauma_duration = 30.minutes

      character.status_effects.create!(
        effect_type: :arena_trauma,
        power: percent,
        expires_at: trauma_duration.from_now,
        source: "Arena defeat",
        metadata: {match_id: match.id}
      )
    rescue => e
      Rails.logger.warn("Failed to apply arena trauma: #{e.message}")
    end
  end
end
