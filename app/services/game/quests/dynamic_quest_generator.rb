# frozen_string_literal: true

module Game
  module Quests
    # DynamicQuestGenerator creates procedural quests from templates or triggers.
    # It can generate quests based on:
    # - World state triggers (resource shortage, territory control)
    # - Character level and progression
    # - Zone-specific objectives
    # - Random daily/weekly quests
    #
    # @example Generate quests from triggers
    #   Game::Quests::DynamicQuestGenerator.new.generate!(
    #     character:,
    #     triggers: {resource_shortage: "ashen_ore", clan_controlled: "rebellion"}
    #   )
    #
    # @example Generate daily quests
    #   Game::Quests::DynamicQuestGenerator.new.generate_daily!(character)
    #
    # @example Generate zone quests
    #   Game::Quests::DynamicQuestGenerator.new.generate_for_zone!(character, zone)
    #
    class DynamicQuestGenerator
      Result = Struct.new(:success, :quests, :assignments, :message, keyword_init: true)

      QUEST_TYPES = %w[kill gather collect escort deliver explore defend].freeze

      OBJECTIVE_TEMPLATES = {
        "kill" => {
          description_template: "Slay %{count} %{target}",
          target_key: "kill_count",
          base_count: 5,
          level_scaling: 0.5
        },
        "gather" => {
          description_template: "Gather %{count} %{target}",
          target_key: "gather_count",
          base_count: 10,
          level_scaling: 0.3
        },
        "collect" => {
          description_template: "Collect %{count} %{target} from enemies",
          target_key: "collect_count",
          base_count: 3,
          level_scaling: 0.2
        },
        "escort" => {
          description_template: "Escort %{target} to %{destination}",
          target_key: "escort_complete",
          base_count: 1,
          level_scaling: 0
        },
        "deliver" => {
          description_template: "Deliver %{item} to %{target}",
          target_key: "deliver_complete",
          base_count: 1,
          level_scaling: 0
        },
        "explore" => {
          description_template: "Explore %{count} locations in %{target}",
          target_key: "explore_count",
          base_count: 3,
          level_scaling: 0.1
        },
        "defend" => {
          description_template: "Defend %{target} for %{count} waves",
          target_key: "defense_waves",
          base_count: 3,
          level_scaling: 0.2
        }
      }.freeze

      REWARD_SCALING = {
        xp_base: 50,
        xp_per_level: 25,
        gold_base: 10,
        gold_per_level: 5,
        difficulty_multiplier: {
          "easy" => 0.75,
          "normal" => 1.0,
          "hard" => 1.5,
          "elite" => 2.0
        }
      }.freeze

      def initialize(assignment_class: QuestAssignment, quest_class: Quest)
        @assignment_class = assignment_class
        @quest_class = quest_class
      end

      # Generate quests from world triggers
      def generate!(character:, triggers:)
        normalized_triggers = triggers.stringify_keys
        assignments = []

        # First, check existing dynamic quests that match triggers
        quest_class.dynamic.active.each do |quest|
          next unless matches_triggers?(quest, normalized_triggers)

          assignment = find_or_create_assignment(quest, character, normalized_triggers)
          assignments << assignment if assignment
        end

        # Generate new procedural quests based on triggers
        procedural_quests = generate_procedural_quests(character, normalized_triggers)
        procedural_quests.each do |quest_data|
          quest = create_dynamic_quest(quest_data)
          assignment = find_or_create_assignment(quest, character, normalized_triggers)
          assignments << assignment if assignment
        end

        Result.new(
          success: true,
          quests: assignments.map(&:quest),
          assignments: assignments,
          message: "Generated #{assignments.size} quests"
        )
      end

      # Generate daily quests for a character
      def generate_daily!(character, count: 3)
        today_key = Date.current.to_s
        assignments = []

        count.times do |i|
          quest_data = generate_daily_quest(character, index: i)
          quest = create_dynamic_quest(quest_data.merge(
            daily_key: "#{today_key}_#{i}",
            expires_at: Date.tomorrow.beginning_of_day
          ))

          assignment = find_or_create_assignment(quest, character, {"daily" => today_key})
          assignments << assignment if assignment
        end

        Result.new(
          success: true,
          quests: assignments.map(&:quest),
          assignments: assignments,
          message: "Generated #{assignments.size} daily quests"
        )
      end

      # Generate zone-specific quests
      def generate_for_zone!(character, zone)
        assignments = []

        # Kill quest for zone enemies
        if zone_has_hostiles?(zone)
          quest_data = generate_kill_quest(character, zone)
          quest = create_dynamic_quest(quest_data)
          assignment = find_or_create_assignment(quest, character, {"zone" => zone.name})
          assignments << assignment if assignment
        end

        # Gather quest for zone resources
        if zone_has_resources?(zone)
          quest_data = generate_gather_quest(character, zone)
          quest = create_dynamic_quest(quest_data)
          assignment = find_or_create_assignment(quest, character, {"zone" => zone.name})
          assignments << assignment if assignment
        end

        # Explore quest for new zones
        if character_new_to_zone?(character, zone)
          quest_data = generate_explore_quest(character, zone)
          quest = create_dynamic_quest(quest_data)
          assignment = find_or_create_assignment(quest, character, {"zone" => zone.name})
          assignments << assignment if assignment
        end

        Result.new(
          success: true,
          quests: assignments.map(&:quest),
          assignments: assignments,
          message: "Generated #{assignments.size} zone quests"
        )
      end

      private

      attr_reader :assignment_class, :quest_class

      def matches_triggers?(quest, triggers)
        rules = quest.metadata.fetch("dynamic_triggers", {})
        return true if rules.blank?

        rules.all? do |key, value|
          case key.to_s
          when "resource_shortage"
            Array(value).map(&:to_s).include?(triggers["resource_shortage"].to_s)
          when "clan_controlled"
            Array(value).map(&:to_s).include?(triggers["clan_controlled"].to_s)
          when "event_key"
            Array(value).map(&:to_s).include?(triggers["event_key"].to_s)
          when "min_level"
            triggers["character_level"].to_i >= value.to_i
          when "max_level"
            triggers["character_level"].to_i <= value.to_i
          when "zone"
            triggers["zone"].to_s == value.to_s
          else
            triggers[key.to_s] == value
          end
        end
      end

      def find_or_create_assignment(quest, character, triggers)
        # Don't re-assign completed quests
        existing = assignment_class.find_by(quest: quest, character: character)
        return nil if existing&.status == "completed"

        assignment_class.find_or_create_by!(quest: quest, character: character) do |assignment|
          assignment.status = :pending
          assignment.progress = {}
          assignment.metadata = {"generated_from" => triggers}
        end
      rescue ActiveRecord::RecordNotUnique
        assignment_class.find_by(quest: quest, character: character)
      end

      def generate_procedural_quests(character, triggers)
        quests = []

        # Resource shortage -> gather quest
        if triggers["resource_shortage"]
          quests << generate_shortage_quest(character, triggers["resource_shortage"])
        end

        # Territory conflict -> kill quest
        if triggers["territory_contested"]
          quests << generate_territory_quest(character, triggers["territory_contested"])
        end

        # World event -> event quest
        if triggers["event_key"]
          quests << generate_event_quest(character, triggers["event_key"])
        end

        quests.compact
      end

      def generate_daily_quest(character, index:)
        quest_type = QUEST_TYPES[index % QUEST_TYPES.size]
        difficulty = %w[easy normal hard].sample

        case quest_type
        when "kill"
          generate_kill_quest_data(character, difficulty)
        when "gather"
          generate_gather_quest_data(character, difficulty)
        when "explore"
          generate_explore_quest_data(character, difficulty)
        else
          generate_generic_quest_data(character, quest_type, difficulty)
        end
      end

      def generate_kill_quest_data(character, difficulty)
        level = character.level
        targets = available_kill_targets(character)
        target = targets.sample || "monsters"
        count = calculate_objective_count("kill", level, difficulty)

        {
          name: "Eliminate #{target.titleize}",
          description: "The land is overrun with #{target}. Thin their numbers to restore peace.",
          quest_type: "dynamic",
          level_required: [level - 2, 1].max,
          objectives: [
            {
              "key" => "kill_#{target.parameterize}",
              "description" => "Slay #{count} #{target.titleize}",
              "target" => count,
              "type" => "kill"
            }
          ],
          rewards: calculate_rewards(level, difficulty),
          metadata: {
            "dynamic" => true,
            "difficulty" => difficulty,
            "target_type" => target,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_gather_quest_data(character, difficulty)
        level = character.level
        resources = available_resources(character)
        resource = resources.sample || "herbs"
        count = calculate_objective_count("gather", level, difficulty)

        {
          name: "Supply Run: #{resource.titleize}",
          description: "Supplies of #{resource} are running low. Gather more for the settlement.",
          quest_type: "dynamic",
          level_required: [level - 2, 1].max,
          objectives: [
            {
              "key" => "gather_#{resource.parameterize}",
              "description" => "Gather #{count} #{resource.titleize}",
              "target" => count,
              "type" => "gather"
            }
          ],
          rewards: calculate_rewards(level, difficulty),
          metadata: {
            "dynamic" => true,
            "difficulty" => difficulty,
            "resource_type" => resource,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_explore_quest_data(character, difficulty)
        level = character.level
        zone = character.current_position&.zone
        zone_name = zone&.name || "the wilderness"
        count = calculate_objective_count("explore", level, difficulty)

        {
          name: "Scouting: #{zone_name}",
          description: "Explore the area to map out points of interest.",
          quest_type: "dynamic",
          level_required: [level - 2, 1].max,
          objectives: [
            {
              "key" => "explore_locations",
              "description" => "Discover #{count} locations in #{zone_name}",
              "target" => count,
              "type" => "explore"
            }
          ],
          rewards: calculate_rewards(level, difficulty),
          metadata: {
            "dynamic" => true,
            "difficulty" => difficulty,
            "zone" => zone_name,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_generic_quest_data(character, quest_type, difficulty)
        level = character.level
        template = OBJECTIVE_TEMPLATES[quest_type] || OBJECTIVE_TEMPLATES["kill"]
        count = calculate_objective_count(quest_type, level, difficulty)

        {
          name: "#{quest_type.titleize} Mission",
          description: "Complete this #{difficulty} #{quest_type} mission.",
          quest_type: "dynamic",
          level_required: [level - 2, 1].max,
          objectives: [
            {
              "key" => "#{quest_type}_objective",
              "description" => "Complete the #{quest_type} objective",
              "target" => count,
              "type" => quest_type
            }
          ],
          rewards: calculate_rewards(level, difficulty),
          metadata: {
            "dynamic" => true,
            "difficulty" => difficulty,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_kill_quest(character, zone)
        enemies = NpcTemplate.hostile.in_zone(zone.name).pluck(:name)
        target = enemies.sample || "hostile creatures"
        count = calculate_objective_count("kill", character.level, "normal")

        {
          name: "Clear #{zone.name}",
          description: "Hostile creatures threaten the area. Eliminate them.",
          quest_type: "dynamic",
          level_required: [character.level - 2, 1].max,
          objectives: [
            {
              "key" => "kill_in_#{zone.name.parameterize}",
              "description" => "Defeat #{count} enemies in #{zone.name}",
              "target" => count,
              "type" => "kill"
            }
          ],
          rewards: calculate_rewards(character.level, "normal"),
          metadata: {
            "dynamic" => true,
            "zone" => zone.name,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_gather_quest(character, zone)
        resources = zone_resources(zone)
        resource = resources.sample || "resources"
        count = calculate_objective_count("gather", character.level, "normal")

        {
          name: "Harvest #{zone.name}",
          description: "Gather valuable resources from this area.",
          quest_type: "dynamic",
          level_required: [character.level - 2, 1].max,
          objectives: [
            {
              "key" => "gather_in_#{zone.name.parameterize}",
              "description" => "Gather #{count} #{resource} in #{zone.name}",
              "target" => count,
              "type" => "gather"
            }
          ],
          rewards: calculate_rewards(character.level, "normal"),
          metadata: {
            "dynamic" => true,
            "zone" => zone.name,
            "resource" => resource,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_explore_quest(character, zone)
        {
          name: "Explore #{zone.name}",
          description: "You've arrived in a new area. Explore and discover its secrets.",
          quest_type: "dynamic",
          level_required: 1,
          objectives: [
            {
              "key" => "explore_#{zone.name.parameterize}",
              "description" => "Explore 5 different tiles in #{zone.name}",
              "target" => 5,
              "type" => "explore"
            }
          ],
          rewards: calculate_rewards(character.level, "easy"),
          metadata: {
            "dynamic" => true,
            "zone" => zone.name,
            "first_visit" => true,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_shortage_quest(character, resource)
        count = calculate_objective_count("gather", character.level, "hard")

        {
          name: "Urgent: #{resource.to_s.titleize} Shortage",
          description: "The settlement desperately needs #{resource}. Help gather supplies!",
          quest_type: "dynamic",
          level_required: 1,
          objectives: [
            {
              "key" => "gather_#{resource.to_s.parameterize}",
              "description" => "Gather #{count} #{resource.to_s.titleize}",
              "target" => count,
              "type" => "gather"
            }
          ],
          rewards: calculate_rewards(character.level, "hard"),
          metadata: {
            "dynamic" => true,
            "shortage_resource" => resource.to_s,
            "urgent" => true,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_territory_quest(character, territory)
        {
          name: "Defend #{territory.to_s.titleize}",
          description: "Enemy forces contest control of #{territory}. Join the defense!",
          quest_type: "dynamic",
          level_required: 1,
          objectives: [
            {
              "key" => "defend_#{territory.to_s.parameterize}",
              "description" => "Defeat 10 enemy combatants in #{territory.to_s.titleize}",
              "target" => 10,
              "type" => "kill"
            },
            {
              "key" => "complete_defense_event",
              "description" => "Complete the defense event",
              "target" => 1,
              "type" => "event"
            }
          ],
          rewards: calculate_rewards(character.level, "elite"),
          metadata: {
            "dynamic" => true,
            "territory" => territory.to_s,
            "pvp_enabled" => true,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def generate_event_quest(character, event_key)
        {
          name: "World Event: #{event_key.to_s.titleize}",
          description: "A world event is underway. Participate to earn rewards!",
          quest_type: "dynamic",
          level_required: 1,
          objectives: [
            {
              "key" => "participate_#{event_key.to_s.parameterize}",
              "description" => "Participate in the #{event_key.to_s.titleize} event",
              "target" => 1,
              "type" => "event"
            }
          ],
          rewards: calculate_rewards(character.level, "hard"),
          metadata: {
            "dynamic" => true,
            "event_key" => event_key.to_s,
            "generated_at" => Time.current.iso8601
          }
        }
      end

      def calculate_objective_count(quest_type, level, difficulty)
        template = OBJECTIVE_TEMPLATES[quest_type] || OBJECTIVE_TEMPLATES["kill"]
        base = template[:base_count]
        scaling = template[:level_scaling]
        multiplier = REWARD_SCALING[:difficulty_multiplier][difficulty] || 1.0

        ((base + (level * scaling)) * multiplier).round
      end

      def calculate_rewards(level, difficulty)
        multiplier = REWARD_SCALING[:difficulty_multiplier][difficulty] || 1.0
        xp = ((REWARD_SCALING[:xp_base] + (level * REWARD_SCALING[:xp_per_level])) * multiplier).round
        gold = ((REWARD_SCALING[:gold_base] + (level * REWARD_SCALING[:gold_per_level])) * multiplier).round

        {
          "xp" => xp,
          "gold" => gold
        }
      end

      def create_dynamic_quest(quest_data)
        # Generate unique key for this dynamic quest
        unique_key = "dynamic_#{Digest::MD5.hexdigest(quest_data.to_json)[0..7]}"

        quest_class.find_or_create_by!(key: unique_key) do |quest|
          quest.title = quest_data[:name]
          quest.summary = quest_data[:description]
          quest.quest_type = quest_data[:quest_type] || "dynamic"
          quest.requirements = {"level" => quest_data[:level_required] || 1}
          quest.rewards = quest_data[:rewards] || {}
          quest.metadata = (quest_data[:metadata] || {}).merge(
            "objectives" => quest_data[:objectives] || []
          )
        end
      end

      def available_kill_targets(character)
        zone = character.current_position&.zone
        return %w[monsters creatures enemies] unless zone

        NpcTemplate.hostile.in_zone(zone.name).pluck(:name).presence ||
          %w[monsters creatures enemies]
      end

      def available_resources(character)
        zone = character.current_position&.zone
        return %w[herbs ore wood] unless zone

        zone_resources(zone).presence || %w[herbs ore wood]
      end

      def zone_resources(zone)
        case zone.biome
        when "forest"
          %w[herbs wood berries mushrooms]
        when "mountain"
          %w[ore crystals stone gems]
        when "plains"
          %w[herbs flax cotton wild_plants]
        when "desert"
          %w[cacti sand_gems oasis_water]
        else
          %w[resources materials]
        end
      end

      def zone_has_hostiles?(zone)
        NpcTemplate.hostile.in_zone(zone.name).exists?
      end

      def zone_has_resources?(zone)
        GatheringNode.where(zone: zone).exists?
      end

      def character_new_to_zone?(character, zone)
        # Check if character has explored this zone before
        !character.quest_assignments
          .joins(:quest)
          .where(quests: {metadata: {zone: zone.name}.to_json})
          .where(status: :completed)
          .exists?
      end
    end
  end
end
