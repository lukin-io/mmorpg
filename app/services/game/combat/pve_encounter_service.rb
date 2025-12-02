# frozen_string_literal: true

module Game
  module Combat
    # Handles PvE combat encounters between players and NPCs
    # Manages battle creation, combat rounds, and rewards
    #
    # @example Start an encounter
    #   service = Game::Combat::PveEncounterService.new(character, npc_template)
    #   result = service.start_encounter!
    #
    # @example Process a combat action
    #   service.process_action!(action_type: :attack)
    #
    class PveEncounterService
      Result = Struct.new(:success, :battle, :message, :combat_log, :rewards, keyword_init: true)

      ACTIONS = %i[attack defend skill flee].freeze

      attr_reader :character, :npc_template, :battle, :errors

      def initialize(character, npc_template, zone: nil)
        @character = character
        @npc_template = npc_template
        @zone = zone || character.position&.zone
        @errors = []
      end

      # Start a new PvE encounter
      #
      # @return [Result] the encounter result
      def start_encounter!
        return failure("Already in combat") if character_in_combat?
        return failure("Character is dead") if character.current_hp <= 0
        return failure("NPC not found") if npc_template.nil?

        ActiveRecord::Base.transaction do
          create_battle!
          create_participants!
          broadcast_combat_started!
        end

        Result.new(
          success: true,
          battle: battle,
          message: "Combat started with #{npc_template.name}!",
          combat_log: ["You engage #{npc_template.name} in combat!"]
        )
      rescue ActiveRecord::RecordInvalid => e
        failure("Failed to start encounter: #{e.message}")
      end

      # Process a combat action from the player
      #
      # @param action_type [Symbol] :attack, :defend, :skill, or :flee
      # @param skill_id [Integer, nil] optional skill ID for :skill actions
      # @return [Result] the action result
      def process_action!(action_type:, skill_id: nil)
        @battle = character.battle_participants.joins(:battle).find_by(battles: {status: :active})&.battle
        return failure("Not in combat") unless battle

        # Get NPC template from battle if not provided
        @npc_template ||= battle.battle_participants.find_by(team: "enemy")&.npc_template

        case action_type.to_sym
        when :attack
          process_attack!
        when :defend
          process_defend!
        when :skill
          process_skill!(skill_id)
        when :flee
          process_flee!
        else
          failure("Unknown action: #{action_type}")
        end
      end

      # Process a full turn with attacks, blocks, and skills
      #
      # @param attacks [Array] array of attack actions [{body_part:, action_key:, slot_index:}]
      # @param blocks [Array] array of block actions [{body_part:, action_key:, slot_index:}]
      # @param skills [Array] array of skill actions
      # @return [Result] the turn result
      def process_turn!(attacks: [], blocks: [], skills: [])
        @battle = character.battle_participants.joins(:battle).find_by(battles: {status: :active})&.battle
        return failure("Not in combat") unless battle

        @npc_template ||= battle.battle_participants.find_by(team: "enemy")&.npc_template
        return failure("Enemy not found") unless npc_template

        # Validate action points
        total_ap_cost = calculate_turn_ap_cost(attacks, blocks, skills)
        max_ap = battle.action_points_per_turn || character.max_action_points
        return failure("Exceeds action points (#{total_ap_cost}/#{max_ap})") if total_ap_cost > max_ap

        player_participant = battle.battle_participants.find_by(team: "player")
        npc_participant = battle.battle_participants.find_by(team: "enemy")

        combat_log = []
        total_player_damage = 0

        # Process player's blocks (set defending state)
        blocks_set = blocks.map { |b| b["body_part"] || b[:body_part] }.compact
        player_participant.update!(is_defending: blocks_set.any?)

        if blocks_set.any?
          combat_log << "You defend your #{blocks_set.join(", ")}."
        end

        # Process player's attacks
        attacks.each do |attack|
          body_part = attack["body_part"] || attack[:body_part]
          action_key = attack["action_key"] || attack[:action_key]

          next if action_key.blank?

          # Calculate damage based on attack type
          base_damage = calculate_damage(character, npc_stats, is_defending: npc_participant.is_defending)
          damage_modifier = (action_key == "aimed") ? 1.3 : 1.0
          damage = (base_damage * damage_modifier).to_i

          # Check for critical
          is_crit = rand(100) < crit_chance(character)
          damage = (damage * 1.5).to_i if is_crit

          total_player_damage += damage
          attack_name = (action_key == "aimed") ? "aimed attack" : "attack"
          combat_log << "You #{attack_name} #{npc_template.name}'s #{body_part} for #{damage} damage#{" (CRITICAL!)" if is_crit}."
        end

        # Apply player damage to NPC
        if total_player_damage > 0
          npc_participant.current_hp = [npc_participant.current_hp - total_player_damage, 0].max
          npc_participant.is_defending = false
          npc_participant.save!

          # Check if NPC defeated
          if npc_participant.current_hp <= 0
            return complete_battle!(winner: :player, combat_log: combat_log)
          end
        end

        # NPC's turn - select random body part to attack
        npc_target = %w[head torso stomach legs].sample
        npc_attacking_blocked_part = blocks_set.include?(npc_target)

        npc_base_damage = calculate_npc_damage(npc_stats, character, is_defending: npc_attacking_blocked_part)
        total_npc_damage = npc_base_damage

        combat_log << "#{npc_template.name} attacks your #{npc_target} for #{total_npc_damage} damage#{" (blocked!)" if npc_attacking_blocked_part}."

        # Apply NPC damage to player
        vitals_service.apply_damage(total_npc_damage, source: npc_template.name)
        player_participant.is_defending = false
        player_participant.save!

        # Check if player defeated
        if character.reload.current_hp <= 0
          return complete_battle!(winner: :npc, combat_log: combat_log)
        end

        # Advance turn
        battle.update!(turn_number: battle.turn_number + 1)
        broadcast_combat_update!(combat_log)

        Result.new(
          success: true,
          battle: battle,
          message: "Turn #{battle.turn_number} completed",
          combat_log: combat_log
        )
      end

      private

      def create_battle!
        @battle = Battle.create!(
          battle_type: :pve,
          status: :active,
          zone: @zone,
          initiator: character,
          turn_number: 1,
          initiative_order: calculate_initiative,
          action_points_per_turn: character.max_action_points
        )
      end

      def create_participants!
        # Player participant
        battle.battle_participants.create!(
          character: character,
          team: "player",
          initiative: character_initiative,
          current_hp: character.current_hp,
          max_hp: character.max_hp,
          is_alive: true
        )

        # NPC participant (virtual character)
        battle.battle_participants.create!(
          npc_template: npc_template,
          team: "enemy",
          initiative: npc_initiative,
          current_hp: npc_max_hp,
          max_hp: npc_max_hp,
          is_alive: true
        )
      end

      def calculate_initiative
        player_init = character_initiative
        npc_init = npc_initiative

        if player_init >= npc_init
          ["player", "enemy"]
        else
          ["enemy", "player"]
        end
      end

      def character_initiative
        # Base initiative from character stats
        base = character.respond_to?(:agility) ? character.agility : 10
        base + rand(1..10)
      end

      def npc_initiative
        npc_stats[:agility] + rand(1..10)
      end

      def npc_stats
        @npc_stats ||= begin
          # Try to get stats from metadata, otherwise generate based on level
          metadata_stats = npc_template.metadata&.dig("stats")
          if metadata_stats.present?
            metadata_stats.with_indifferent_access
          else
            {
              attack: npc_template.metadata&.dig("base_damage") || npc_template.level * 3 + 5,
              defense: npc_template.level * 2 + 3,
              agility: npc_template.level + 5,
              hp: npc_template.metadata&.dig("health") || npc_template.level * 10 + 20
            }.with_indifferent_access
          end
        end
      end

      def npc_max_hp
        npc_stats[:hp] || (npc_template.level * 10 + 20)
      end

      def process_attack!
        player_participant = battle.battle_participants.find_by(team: "player")
        npc_participant = battle.battle_participants.find_by(team: "enemy")

        combat_log = []

        # Player attacks NPC
        player_damage = calculate_damage(character, npc_stats, is_defending: npc_participant.is_defending)
        is_crit = rand(100) < crit_chance(character)
        player_damage = (player_damage * 1.5).to_i if is_crit

        npc_participant.current_hp = [npc_participant.current_hp - player_damage, 0].max
        npc_participant.is_defending = false
        npc_participant.save!

        combat_log << "You attack #{npc_template.name} for #{player_damage} damage#{" (CRITICAL!)" if is_crit}."

        # Check if NPC defeated
        if npc_participant.current_hp <= 0
          return complete_battle!(winner: :player, combat_log: combat_log)
        end

        # NPC attacks player
        npc_damage = calculate_npc_damage(npc_stats, character, is_defending: player_participant.is_defending)
        player_participant.is_defending = false
        player_participant.save!

        # Apply damage to character
        vitals_service.apply_damage(npc_damage, source: npc_template.name)
        combat_log << "#{npc_template.name} attacks you for #{npc_damage} damage."

        # Check if player defeated
        if character.reload.current_hp <= 0
          return complete_battle!(winner: :npc, combat_log: combat_log)
        end

        # Advance turn
        battle.update!(turn_number: battle.turn_number + 1)
        broadcast_combat_update!(combat_log)

        Result.new(
          success: true,
          battle: battle,
          message: "Combat continues",
          combat_log: combat_log
        )
      end

      def process_defend!
        player_participant = battle.battle_participants.find_by(team: "player")
        battle.battle_participants.find_by(team: "enemy")

        player_participant.update!(is_defending: true)

        combat_log = ["You take a defensive stance, reducing incoming damage."]

        # NPC still attacks
        npc_damage = calculate_npc_damage(npc_stats, character, is_defending: true)
        vitals_service.apply_damage(npc_damage, source: npc_template.name)
        combat_log << "#{npc_template.name} attacks you for #{npc_damage} damage (reduced by defense)."

        if character.reload.current_hp <= 0
          return complete_battle!(winner: :npc, combat_log: combat_log)
        end

        battle.update!(turn_number: battle.turn_number + 1)
        broadcast_combat_update!(combat_log)

        Result.new(
          success: true,
          battle: battle,
          message: "Defending",
          combat_log: combat_log
        )
      end

      def process_skill!(skill_id)
        return failure("No skill specified") unless skill_id

        # Find the skill (can be ability or skill_node)
        skill = find_skill(skill_id)
        return failure("Skill not found or not unlocked") unless skill

        # Get NPC participant as target
        npc_participant = battle.battle_participants.find_by(participant_type: "npc")
        return failure("No target found") unless npc_participant

        # Create a target wrapper for the NPC
        npc_target = NpcCombatTarget.new(npc_participant, npc_template)

        # Execute the skill
        executor = Game::Combat::SkillExecutor.new(
          caster: character,
          target: npc_target,
          skill: skill,
          battle: battle
        )

        result = executor.execute!
        return failure(result.message) unless result.success

        combat_log = [result.message]

        # Check if NPC is defeated
        if npc_target.current_hp <= 0
          return complete_battle!(winner: :player, combat_log: combat_log)
        end

        # NPC counterattack
        npc_damage = calculate_npc_damage(npc_stats, character, is_defending: false)
        vitals_service.apply_damage(npc_damage, source: npc_template.name)
        combat_log << "#{npc_template.name} counterattacks for #{npc_damage} damage!"

        # Check if player is defeated
        if character.reload.current_hp <= 0
          return complete_battle!(winner: :npc, combat_log: combat_log)
        end

        battle.update!(turn_number: battle.turn_number + 1)
        broadcast_combat_update!(combat_log)

        Result.new(
          success: true,
          battle: battle,
          message: result.message,
          combat_log: combat_log
        )
      end

      def find_skill(skill_id)
        skill_id = skill_id.to_s

        # Check if it's an ability (ability_123)
        if skill_id.start_with?("ability_")
          ability_id = skill_id.sub("ability_", "").to_i
          return character.character_class&.abilities&.find_by(id: ability_id, kind: "active")
        end

        # Check if it's a skill node (skill_123)
        if skill_id.start_with?("skill_")
          node_id = skill_id.sub("skill_", "").to_i
          return character.skill_nodes.where(node_type: "active").find_by(id: node_id)
        end

        # Try direct ID lookup
        character.skill_nodes.where(node_type: "active").find_by(id: skill_id) ||
          character.character_class&.abilities&.find_by(id: skill_id, kind: "active")
      end

      # Wrapper class for NPC combat target
      class NpcCombatTarget
        attr_accessor :current_hp, :current_mp

        def initialize(participant, template)
          @participant = participant
          @template = template
          @current_hp = participant.current_hp || template.health
          @current_mp = participant.current_mp || 0
        end

        def name
          @template.name
        end

        def id
          @participant.id
        end

        def max_hp
          @template.health
        end

        def save!
          @participant.update!(current_hp: @current_hp, current_mp: @current_mp)
        end
      end

      def process_flee!
        # Flee chance based on agility comparison
        flee_chance = 30 + (character_initiative - npc_initiative) * 2
        flee_chance = flee_chance.clamp(10, 90)

        combat_log = []

        if rand(100) < flee_chance
          battle.update!(status: :completed)
          combat_log << "You successfully flee from #{npc_template.name}!"

          broadcast_combat_ended!("fled")

          Result.new(
            success: true,
            battle: battle,
            message: "Escaped!",
            combat_log: combat_log
          )
        else
          combat_log << "You failed to flee!"

          # NPC gets a free attack
          npc_damage = calculate_npc_damage(npc_stats, character, is_defending: false)
          vitals_service.apply_damage(npc_damage, source: npc_template.name)
          combat_log << "#{npc_template.name} attacks you for #{npc_damage} damage as you try to escape!"

          if character.reload.current_hp <= 0
            return complete_battle!(winner: :npc, combat_log: combat_log)
          end

          battle.update!(turn_number: battle.turn_number + 1)
          broadcast_combat_update!(combat_log)

          Result.new(
            success: false,
            battle: battle,
            message: "Failed to flee",
            combat_log: combat_log
          )
        end
      end

      def complete_battle!(winner:, combat_log:)
        battle.update!(status: :completed)

        rewards = nil
        if winner == :player
          rewards = grant_rewards!
          combat_log << "Victory! You defeated #{npc_template.name}."
          combat_log << "Gained #{rewards[:xp]} XP and #{rewards[:gold]} gold." if rewards
        else
          combat_log << "Defeat! You were slain by #{npc_template.name}."
          Characters::DeathHandler.call(character)
        end

        broadcast_combat_ended!((winner == :player) ? "victory" : "defeat")

        Result.new(
          success: winner == :player,
          battle: battle,
          message: (winner == :player) ? "Victory!" : "Defeat!",
          combat_log: combat_log,
          rewards: rewards
        )
      end

      def grant_rewards!
        xp = calculate_xp_reward
        gold = calculate_gold_reward

        character.gain_experience!(xp, source: "Defeated #{npc_template.name}")
        character.add_currency!(:gold, gold, source: "Combat loot")

        # Check for item drops
        item = roll_item_drop
        if item
          character.inventory.add_item!(item, source: "Dropped by #{npc_template.name}")
        end

        {xp: xp, gold: gold, item: item&.name}
      rescue => e
        Rails.logger.error("Failed to grant PvE rewards: #{e.message}")
        {xp: 0, gold: 0}
      end

      def calculate_xp_reward
        base = npc_template.level * 10
        level_diff = npc_template.level - character.level

        # Bonus for fighting higher level NPCs
        multiplier = if level_diff > 0
          1.0 + (level_diff * 0.1)
        elsif level_diff < -5
          0.5 # Reduced XP for much lower level NPCs
        else
          1.0
        end

        (base * multiplier).round
      end

      def calculate_gold_reward
        base = npc_template.level * 2 + 5
        (base * (0.8 + rand * 0.4)).round # 80% to 120% of base
      end

      def roll_item_drop
        return nil unless npc_template.loot_table.present?

        # 20% base drop chance
        return nil unless rand(100) < 20

        loot = npc_template.loot_table.sample
        ItemTemplate.find_by(key: loot["item_key"]) if loot
      end

      def calculate_damage(attacker, defender_stats, is_defending: false)
        base_attack = attacker.respond_to?(:attack_power) ? attacker.attack_power : 10
        base_defense = defender_stats[:defense] || 5

        defense_mult = is_defending ? 1.5 : 1.0
        effective_defense = (base_defense * defense_mult).to_i

        damage = base_attack - (effective_defense / 2)
        damage += rand(1..5)
        [damage, 1].max
      end

      def calculate_npc_damage(attacker_stats, defender, is_defending: false)
        base_attack = attacker_stats[:attack] || 10
        base_defense = defender.respond_to?(:defense) ? defender.defense : 5

        defense_mult = is_defending ? 1.5 : 1.0
        effective_defense = (base_defense * defense_mult).to_i

        damage = base_attack - (effective_defense / 2)
        damage += rand(1..3)
        [damage, 1].max
      end

      def crit_chance(attacker)
        base = attacker.respond_to?(:critical_chance) ? attacker.critical_chance : 5
        [base, 50].min
      end

      # Calculate total action point cost for a turn
      # @param attacks [Array] array of attack actions
      # @param blocks [Array] array of block actions
      # @param skills [Array] array of skill actions
      # @return [Integer] total AP cost
      def calculate_turn_ap_cost(attacks, blocks, skills)
        attack_costs = load_action_costs("attack_types")
        block_costs = load_action_costs("block_types")

        # Calculate attack costs
        attack_total = attacks.sum do |attack|
          key = attack["action_key"] || attack[:action_key]
          attack_costs.dig(key, "action_cost") || 0
        end

        # Calculate block costs
        block_total = blocks.sum do |block|
          key = block["action_key"] || block[:action_key]
          block_costs.dig(key, "action_cost") || 30 # Default block cost
        end

        # Calculate skill costs
        skill_total = skills.sum do |skill|
          skill["cost"] || skill[:cost] || 0
        end

        # Add multi-attack penalty
        penalty = calculate_multi_attack_penalty(attacks.size)

        attack_total + block_total + skill_total + penalty
      end

      # Load action costs from config
      def load_action_costs(category)
        config_path = Rails.root.join("config/gameplay/combat_actions.yml")
        return {} unless File.exist?(config_path)

        config = YAML.load_file(config_path, permitted_classes: [Symbol])
        config[category] || {}
      end

      # Calculate penalty for multiple attacks
      def calculate_multi_attack_penalty(attack_count)
        return 0 if attack_count <= 1

        penalties = [0, 0, 25, 75, 150, 250]
        penalties[[attack_count, penalties.size - 1].min]
      end

      def character_in_combat?
        character.battle_participants.joins(:battle).where(battles: {status: :active}).exists?
      end

      def vitals_service
        @vitals_service ||= Characters::VitalsService.new(character)
      end

      def broadcast_combat_started!
        ActionCable.server.broadcast(
          "character:#{character.id}:combat",
          {
            type: "combat_started",
            battle_id: battle.id,
            enemy_name: npc_template.name,
            enemy_level: npc_template.level,
            enemy_hp: npc_max_hp,
            enemy_max_hp: npc_max_hp
          }
        )
      end

      def broadcast_combat_update!(combat_log)
        npc_participant = battle.battle_participants.find_by(team: "enemy")

        ActionCable.server.broadcast(
          "character:#{character.id}:combat",
          {
            type: "combat_update",
            battle_id: battle.id,
            turn: battle.turn_number,
            player_hp: character.current_hp,
            player_max_hp: character.max_hp,
            enemy_hp: npc_participant.current_hp,
            enemy_max_hp: npc_participant.max_hp,
            combat_log: combat_log
          }
        )
      end

      def broadcast_combat_ended!(outcome)
        ActionCable.server.broadcast(
          "character:#{character.id}:combat",
          {
            type: "combat_ended",
            battle_id: battle.id,
            outcome: outcome
          }
        )
      end

      def failure(message)
        errors << message
        Result.new(success: false, message: message, combat_log: [message])
      end
    end
  end
end
