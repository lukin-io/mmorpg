# frozen_string_literal: true

module Arena
  # Manages arena fight application lifecycle
  # Handles creating, accepting, and cancelling fight applications
  #
  # @example Create a duel application
  #   handler = Arena::ApplicationHandler.new
  #   result = handler.create(
  #     character: current_character,
  #     room: arena_room,
  #     params: { fight_type: "duel", timeout_seconds: 180 }
  #   )
  #
  # @example Accept an application
  #   handler.accept(application: app, acceptor: character)
  #
  class ApplicationHandler
    Result = Struct.new(:success?, :application, :match, :errors, keyword_init: true)

    # Create a new fight application
    #
    # @param character [Character] the applicant
    # @param room [ArenaRoom] the arena room
    # @param params [Hash] application parameters
    # @return [Result] result with application or errors
    def create(character:, room:, params:)
      # Validate room access
      unless room.accessible_by?(character)
        return Result.new(success?: false, errors: ["You cannot access this arena room"])
      end

      # Check for existing application
      if character_has_active_application?(character)
        return Result.new(success?: false, errors: ["You already have an active fight application"])
      end

      # Check room capacity
      unless room.has_capacity?
        return Result.new(success?: false, errors: ["This arena room is at capacity"])
      end

      application = ArenaApplication.new(
        arena_room: room,
        applicant: character,
        fight_type: params[:fight_type] || :duel,
        fight_kind: params[:fight_kind] || :free,
        timeout_seconds: params[:timeout_seconds] || 180,
        trauma_percent: params[:trauma_percent] || 30,
        team_count: params[:team_count],
        team_level_min: params[:team_level_min],
        team_level_max: params[:team_level_max],
        enemy_count: params[:enemy_count],
        enemy_level_min: params[:enemy_level_min],
        enemy_level_max: params[:enemy_level_max],
        wait_minutes: params[:wait_minutes] || 10,
        closed_fight: params[:closed_fight] || false
      )

      if application.save
        broadcast_new_application(application)
        Result.new(success?: true, application: application)
      else
        Result.new(success?: false, errors: application.errors.full_messages)
      end
    end

    # Accept an existing application (start the fight)
    #
    # @param application [ArenaApplication] the application to accept
    # @param acceptor [Character] the character accepting
    # @return [Result] result with match or errors
    def accept(application:, acceptor:)
      # NPC applications have different acceptance rules
      if application.npc_application?
        return accept_npc_application(application: application, acceptor: acceptor)
      end

      unless application.acceptable_by?(acceptor)
        return Result.new(success?: false, errors: ["You cannot accept this application"])
      end

      ActiveRecord::Base.transaction do
        # Create the match
        match = create_match_from_applications(application, acceptor)

        # Update both applications
        application.update!(
          status: :matched,
          matched_at: Time.current,
          arena_match: match
        )

        # Create acceptor's application record
        acceptor_app = ArenaApplication.create!(
          arena_room: application.arena_room,
          applicant: acceptor,
          fight_type: application.fight_type,
          fight_kind: application.fight_kind,
          timeout_seconds: application.timeout_seconds,
          trauma_percent: application.trauma_percent,
          status: :matched,
          matched_with: application,
          matched_at: Time.current,
          arena_match: match
        )

        application.update!(matched_with: acceptor_app)

        # Schedule match start
        schedule_match_start(match, application.timeout_seconds)

        broadcast_match_created(match, application)

        Result.new(success?: true, application: application, match: match)
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [e.message])
    end

    # Accept an NPC application (player vs bot)
    #
    # @param application [ArenaApplication] the NPC application to accept
    # @param acceptor [Character] the player character accepting
    # @return [Result] result with match or errors
    def accept_npc_application(application:, acceptor:)
      # Validate room access
      unless application.arena_room.accessible_by?(acceptor)
        return Result.new(success?: false, errors: ["You cannot access this arena room"])
      end

      # Check if player already in combat
      if acceptor.in_combat?
        return Result.new(success?: false, errors: ["You are already in combat"])
      end

      ActiveRecord::Base.transaction do
        # Create the match
        match = create_npc_match(application, acceptor)

        # Update application
        application.update!(
          status: :matched,
          matched_at: Time.current,
          arena_match: match
        )

        # NPC fights start immediately (shorter countdown for training)
        npc_countdown = 5 # 5 seconds for NPC fights
        schedule_match_start(match, npc_countdown)

        broadcast_npc_match_created(match, application, acceptor)

        Result.new(success?: true, application: application, match: match)
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [e.message])
    end

    # Cancel an application
    #
    # @param application [ArenaApplication] the application to cancel
    # @param character [Character] the character cancelling (must be applicant)
    # @return [Result] result with success status
    def cancel(application:, character:)
      unless application.applicant == character
        return Result.new(success?: false, errors: ["You can only cancel your own applications"])
      end

      unless application.open?
        return Result.new(success?: false, errors: ["This application cannot be cancelled"])
      end

      application.update!(status: :cancelled)
      broadcast_application_cancelled(application)

      Result.new(success?: true, application: application)
    end

    private

    def character_has_active_application?(character)
      ArenaApplication.active.exists?(applicant: character)
    end

    def create_match_from_applications(application, acceptor)
      match = ArenaMatch.create!(
        arena_room: application.arena_room,
        arena_season: ArenaSeason.current.first,
        match_type: application.fight_type,
        status: :pending,
        metadata: {
          fight_kind: application.fight_kind,
          timeout_seconds: application.timeout_seconds,
          trauma_percent: application.trauma_percent
        }
      )

      # Add participants
      ArenaParticipation.create!(
        arena_match: match,
        character: application.applicant,
        user: application.applicant.user,
        team: "a",
        joined_at: Time.current
      )

      ArenaParticipation.create!(
        arena_match: match,
        character: acceptor,
        user: acceptor.user,
        team: "b",
        joined_at: Time.current
      )

      match
    end

    def create_npc_match(application, acceptor)
      npc = application.npc_template

      match = ArenaMatch.create!(
        arena_room: application.arena_room,
        arena_season: ArenaSeason.current.first,
        match_type: application.fight_type,
        status: :pending,
        metadata: {
          fight_kind: application.fight_kind,
          timeout_seconds: application.timeout_seconds,
          trauma_percent: application.trauma_percent,
          is_npc_fight: true,
          npc_template_id: npc.id,
          npc_name: npc.name,
          npc_difficulty: npc.arena_difficulty,
          npc_ai_behavior: npc.ai_behavior
        }
      )

      # Add player participant (team "a")
      ArenaParticipation.create!(
        arena_match: match,
        character: acceptor,
        user: acceptor.user,
        team: "a",
        joined_at: Time.current
      )

      # Add NPC participant (team "b")
      # Initialize NPC HP in metadata
      npc_hp = npc.health
      ArenaParticipation.create!(
        arena_match: match,
        npc_template: npc,
        team: "b",
        joined_at: Time.current,
        metadata: {
          "current_hp" => npc_hp,
          "max_hp" => npc_hp
        }
      )

      match
    end

    def schedule_match_start(match, countdown_seconds)
      # Update match with start time
      starts_at = Time.current + countdown_seconds.seconds
      match.update!(metadata: match.metadata.merge(starts_at: starts_at.iso8601))

      # Schedule the match start job
      Arena::MatchStarterJob.set(wait: countdown_seconds.seconds).perform_later(match.id)
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

    def broadcast_match_created(match, application)
      ActionCable.server.broadcast(
        "arena:room:#{application.arena_room_id}",
        {
          type: "match_created",
          match_id: match.id,
          application_id: application.id
        }
      )

      # Notify participants (only player participants have user_id)
      match.arena_participations.players.each do |participation|
        ActionCable.server.broadcast(
          "user:#{participation.user_id}:notifications",
          {
            type: "arena_match_starting",
            match_id: match.id,
            countdown: application.timeout_seconds
          }
        )
      end
    end

    def broadcast_npc_match_created(match, application, acceptor)
      # Notify room that application was accepted
      ActionCable.server.broadcast(
        "arena:room:#{application.arena_room_id}",
        {
          type: "npc_match_created",
          match_id: match.id,
          application_id: application.id,
          npc_name: application.npc_template&.name,
          player_name: acceptor.name
        }
      )

      # Notify the player
      ActionCable.server.broadcast(
        "user:#{acceptor.user_id}:notifications",
        {
          type: "arena_npc_match_starting",
          match_id: match.id,
          countdown: 5,
          npc_name: application.npc_template&.name,
          npc_level: application.npc_template&.level,
          npc_difficulty: application.npc_template&.arena_difficulty
        }
      )
    end

    def broadcast_application_cancelled(application)
      ActionCable.server.broadcast(
        "arena:room:#{application.arena_room_id}",
        {
          type: "application_cancelled",
          application_id: application.id
        }
      )
    end

    def application_payload(application)
      payload = {
        id: application.id,
        fight_type: application.fight_type,
        fight_kind: application.fight_kind,
        applicant_name: application.applicant_name,
        applicant_level: application.applicant_level,
        timeout_seconds: application.timeout_seconds,
        trauma_percent: application.trauma_percent,
        expires_at: application.expires_at&.iso8601
      }

      # Add NPC-specific fields
      if application.npc_application?
        payload.merge!(
          is_npc: true,
          npc_difficulty: application.npc_difficulty,
          npc_avatar: application.npc_template&.avatar_emoji
        )
      end

      payload
    end
  end
end
