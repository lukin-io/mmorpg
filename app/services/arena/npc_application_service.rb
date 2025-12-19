# frozen_string_literal: true

module Arena
  # Creates arena applications on behalf of NPC bots
  # These applications appear in arena rooms for players to accept
  #
  # Purpose: Generate training fights with arena bots
  #
  # Inputs:
  #   - room: ArenaRoom where the NPC will create an application
  #   - npc_template: NpcTemplate for the arena bot (optional, will sample if not provided)
  #   - difficulty: Filter for NPC difficulty (optional)
  #
  # Returns:
  #   Result struct with success status and application or errors
  #
  # Usage:
  #   service = Arena::NpcApplicationService.new
  #   result = service.create_for_room(room: arena_room)
  #   # => Result(success?: true, application: ArenaApplication)
  #
  #   result = service.create_with_template(room: arena_room, npc_template: template)
  #   # => Result(success?: true, application: ArenaApplication)
  #
  class NpcApplicationService
    Result = Struct.new(:success?, :application, :errors, keyword_init: true)

    # NPC applications have shorter timeouts than player applications
    NPC_TIMEOUT_SECONDS = 120
    NPC_TRAUMA_PERCENT = 10 # Low trauma for training fights
    NPC_WAIT_MINUTES = 5

    # Create an application for a random NPC appropriate for the room
    #
    # @param room [ArenaRoom] the arena room
    # @param difficulty [Symbol, nil] optional difficulty filter (:easy, :medium, :hard)
    # @param rng [Random] random number generator for determinism
    # @return [Result] result with application or errors
    def create_for_room(room:, difficulty: nil, rng: Random.new)
      npc_config = Game::World::ArenaNpcConfig.sample_npc(
        room.slug,
        difficulty: difficulty,
        rng: rng
      )

      if npc_config.nil?
        return Result.new(success?: false, errors: ["No NPC available for this room"])
      end

      npc_template = find_or_create_npc_template(npc_config)
      create_application(room: room, npc_template: npc_template)
    end

    # Create an application for a specific NPC template
    #
    # @param room [ArenaRoom] the arena room
    # @param npc_template [NpcTemplate] the NPC template to use
    # @return [Result] result with application or errors
    def create_with_template(room:, npc_template:)
      unless npc_template.arena_bot?
        return Result.new(success?: false, errors: ["NPC template is not an arena bot"])
      end

      create_application(room: room, npc_template: npc_template)
    end

    # Create multiple NPC applications for a room (for initial spawning)
    #
    # @param room [ArenaRoom] the arena room
    # @param count [Integer] number of applications to create
    # @param rng [Random] random number generator for determinism
    # @return [Array<Result>] array of results
    def spawn_batch(room:, count:, rng: Random.new)
      results = []
      difficulties = [:easy, :medium, :hard]

      count.times do |i|
        # Rotate through difficulties
        difficulty = difficulties[i % difficulties.length]
        results << create_for_room(room: room, difficulty: difficulty, rng: rng)
      end

      results
    end

    private

    def create_application(room:, npc_template:)
      # Check if this NPC already has an open application in this room
      if ArenaApplication.open.exists?(arena_room: room, npc_template: npc_template)
        return Result.new(success?: false, errors: ["This NPC already has an open application"])
      end

      # Check room capacity
      unless room.has_capacity?
        return Result.new(success?: false, errors: ["Arena room is at capacity"])
      end

      application = ArenaApplication.new(
        arena_room: room,
        npc_template: npc_template,
        fight_type: :duel,
        fight_kind: determine_fight_kind(npc_template),
        timeout_seconds: NPC_TIMEOUT_SECONDS,
        trauma_percent: NPC_TRAUMA_PERCENT,
        wait_minutes: NPC_WAIT_MINUTES,
        metadata: build_npc_metadata(npc_template)
      )

      if application.save
        broadcast_new_application(application)
        Result.new(success?: true, application: application)
      else
        Result.new(success?: false, errors: application.errors.full_messages)
      end
    end

    def find_or_create_npc_template(npc_config)
      key = npc_config[:key].to_s

      template = NpcTemplate.find_by(npc_key: key)
      return template if template

      # Create new template from config
      NpcTemplate.create!(
        npc_key: key,
        name: npc_config[:name],
        role: "arena_bot",
        level: npc_config[:level] || 1,
        dialogue: npc_config[:dialogue] || "...",
        metadata: {
          health: npc_config[:hp],
          base_damage: npc_config[:damage],
          xp_reward: npc_config[:xp] || 10,
          difficulty: npc_config.dig(:metadata, :difficulty),
          ai_behavior: npc_config.dig(:metadata, :ai_behavior),
          arena_rooms: npc_config.dig(:metadata, :arena_rooms),
          description: npc_config.dig(:metadata, :description),
          avatar: npc_config.dig(:metadata, :avatar)
        }.compact
      )
    end

    def determine_fight_kind(npc_template)
      # Training fights are typically no_weapons for beginners
      difficulty = npc_template.arena_difficulty

      case difficulty
      when "easy"
        :no_weapons
      when "medium"
        :no_artifacts
      else
        :free
      end
    end

    def build_npc_metadata(npc_template)
      {
        "is_npc" => true,
        "npc_name" => npc_template.name,
        "npc_level" => npc_template.level,
        "difficulty" => npc_template.arena_difficulty,
        "ai_behavior" => npc_template.ai_behavior,
        "avatar" => npc_template.avatar_emoji
      }
    end

    def broadcast_new_application(application)
      ActionCable.server.broadcast(
        "arena:room:#{application.arena_room_id}",
        {
          type: "new_application",
          application: application_payload(application)
        }
      )
    end

    def application_payload(application)
      {
        id: application.id,
        fight_type: application.fight_type,
        fight_kind: application.fight_kind,
        applicant_name: application.applicant_name,
        applicant_level: application.applicant_level,
        timeout_seconds: application.timeout_seconds,
        trauma_percent: application.trauma_percent,
        expires_at: application.expires_at&.iso8601,
        is_npc: true,
        npc_difficulty: application.npc_difficulty,
        npc_avatar: application.npc_template&.avatar_emoji
      }
    end
  end
end
