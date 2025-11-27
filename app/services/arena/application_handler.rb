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

      # Notify participants
      match.arena_participations.each do |participation|
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
      {
        id: application.id,
        fight_type: application.fight_type,
        fight_kind: application.fight_kind,
        applicant_name: application.applicant.name,
        applicant_level: application.applicant.level,
        timeout_seconds: application.timeout_seconds,
        trauma_percent: application.trauma_percent,
        expires_at: application.expires_at&.iso8601
      }
    end
  end
end
