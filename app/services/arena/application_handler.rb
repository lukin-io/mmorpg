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

    def initialize(publisher: Arena::RealtimePublisher.new, logger: Rails.logger)
      @publisher = publisher
      @logger = logger
    end

    # Create a new fight application
    #
    # @param character [Character] the applicant
    # @param room [ArenaRoom] the arena room
    # @param params [Hash] application parameters
    # @return [Result] result with application or errors
    def create(character:, room:, params:)
      result = ActiveRecord::Base.transaction do
        room.lock!
        character.lock!

        if (error = application_creation_error(character, room))
          Result.new(success?: false, errors: [error])
        else
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
            wait_minutes: params[:wait_minutes] || 10
          )

          # The captured Group form normalizes a requested 1x1 to 1x2.
          if application.team_battle? && [application.team_count_before_type_cast, application.enemy_count_before_type_cast].all? { |value| value.to_s == "1" }
            application.enemy_count = 2
          end

          equipment_error = EquipmentRule.new(application.fight_kind).rejection_reason(character)
          if equipment_error
            Result.new(success?: false, errors: [equipment_error])
          elsif application.save
            if application.team_battle?
              application.arena_application_memberships.create!(character:, team: "a")
              ActiveRecord.after_all_transactions_commit { enqueue_application_deadline(application) }
            end
            Result.new(success?: true, application: application)
          else
            Result.new(success?: false, errors: application.errors.full_messages)
          end
        end
      end

      ActiveRecord.after_all_transactions_commit { broadcast_new_application(result.application) } if result.success?
      result
    rescue ArgumentError, ActiveRecord::RecordInvalid => error
      Result.new(success?: false, errors: [error.message])
    end

    # Reserve a human Duel; its applicant must explicitly confirm the start.
    #
    # @param application [ArenaApplication] the application to accept
    # @param acceptor [Character] the character accepting
    # @return [Result] result with match or errors
    def accept(application:, acceptor:, team: nil)
      return GroupAssembly.new(publisher:).join(application:, character: acceptor, team:) if application.team_battle?
      # NPC applications have different acceptance rules
      if application.npc_application?
        return accept_npc_application(application: application, acceptor: acceptor)
      end

      ActiveRecord::Base.transaction do
        room = application.arena_room
        room.lock!
        application.lock!
        lock_characters!(application.applicant, acceptor)

        if (error = application_acceptance_error(application, acceptor, room))
          Result.new(success?: false, errors: [error])
        else
          matched_at = Time.current
          starts_at = nil
          match = create_match_from_applications(application, acceptor)

          application.update!(
            status: :matched,
            matched_at:,
            starts_at:,
            arena_match: match
          )

          acceptor_app = ArenaApplication.create!(
            arena_room: room,
            applicant: acceptor,
            fight_type: application.fight_type,
            fight_kind: application.fight_kind,
            timeout_seconds: application.timeout_seconds,
            trauma_percent: application.trauma_percent,
            status: :matched,
            matched_with: application,
            matched_at:,
            starts_at:,
            arena_match: match
          )

          application.update!(matched_with: acceptor_app)
          ActiveRecord.after_all_transactions_commit do
            broadcast_match_created(match, application)
          end

          Result.new(success?: true, application: application, match: match)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [e.message])
    end

    # Confirm or refuse a reserved human Duel. Locks the reservation, match and
    # both players; start rechecks admission before entering the shared engine.
    # Refusal reopens the original offer and cancels only its unused match.
    # Returns Result; no combat/reward state is created by refusal or retries.
    def confirm_duel(match:, character:, refuse: false)
      return Result.new(success?: false, errors: ["This is not an Arena Duel reservation"]) unless match.arena_room && match.metadata.to_h["duel_applicant_id"].present?

      ActiveRecord::Base.transaction do
        match.arena_room.lock!
        match.lock!
        applications = match.arena_applications.order(:id).lock.to_a
        original = applications.find { |entry| entry.applicant_id == match.metadata["duel_applicant_id"] }
        opponent = applications.find { |entry| entry != original }
        next Result.new(success?: false, errors: ["This Duel is no longer awaiting confirmation"]) unless match.awaiting_duel_confirmation? && original && opponent
        next Result.new(success?: false, errors: ["Only the applicant can start this Duel"]) unless refuse || original.applicant_id == character.id
        next Result.new(success?: false, errors: ["You are not part of this Duel"]) unless applications.any? { |entry| entry.applicant_id == character.id }

        lock_characters!(*applications.map(&:applicant))
        if refuse
          opponent.update!(status: :cancelled, matched_with: nil)
          original.update!(status: original.deadline_passed? ? :expired : :open, matched_with: nil,
            matched_at: nil, starts_at: nil, arena_match: nil)
          match.update!(status: :cancelled)
          ActiveRecord.after_all_transactions_commit do
            broadcast_new_application(original)
            CombatBroadcaster.new(match).broadcast_state_refresh(reason: :duel_refused)
          end
        else
          next Result.new(success?: false, errors: ["Application has expired; refuse the Duel to leave"]) if original.deadline_passed?
          error = applications.filter_map do |entry|
            player = entry.applicant
            if !match.arena_room.accessible_by?(player)
              "Arena room is unavailable"
            elsif player.in_combat? || player.arena_participations.joins(:arena_match).merge(ArenaMatch.active).where.not(arena_match: match).exists?
              "Player is already in another fight"
            elsif !entry.character_hp_sufficient?(player)
              "Recover before fighting: minimum 50% HP"
            else
              EquipmentRule.new(original.fight_kind).rejection_reason(player)
            end
          end.first
          next Result.new(success?: false, errors: [error]) if error

          match.update!(metadata: match.metadata.merge("duel_start_confirmed" => true))
          CombatProcessor.new(match).start_match
        end
        Result.new(success?: true, application: original, match: match)
      end
    end

    # Accept an NPC application (player vs bot)
    #
    # @param application [ArenaApplication] the NPC application to accept
    # @param acceptor [Character] the player character accepting
    # @return [Result] result with match or errors
    def accept_npc_application(application:, acceptor:)
      ActiveRecord::Base.transaction do
        # Match the existing player-accept order. Region/room access and the
        # open application must remain valid until the fight is persisted.
        application.arena_room.lock!
        application.lock!
        acceptor.lock!

        unless application.arena_room.accessible_by?(acceptor)
          next Result.new(success?: false, errors: ["This arena room is unavailable"])
        end

        unless application.arena_room.has_capacity?
          next Result.new(success?: false, errors: ["Arena room is full"])
        end

        unless application.acceptable_by?(acceptor)
          next Result.new(success?: false, errors: [application.rejection_reason_for(acceptor) || "You cannot accept this application"])
        end

        # Check if player already in combat
        if character_has_active_match?(acceptor)
          next Result.new(success?: false, errors: ["You are already in combat"])
        end
        if character_has_active_application?(acceptor)
          next Result.new(success?: false, errors: ["You already have an active fight application"])
        end

        # Create the match
        match = create_npc_match(application, acceptor)

        # Update application
        application.update!(
          status: :matched,
          matched_at: Time.current,
          arena_match: match
        )

        # NPC training fights enter the captured active combat screen
        # immediately after accepting the open side.
        Arena::CombatProcessor.new(match).start_match

        ActiveRecord.after_all_transactions_commit do
          broadcast_npc_match_created(match, application, acceptor)
        end

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
      return GroupAssembly.new(publisher:).withdraw(application:, character:) if application.team_battle?
      ActiveRecord::Base.transaction do
        application.lock!

        if application.applicant_id != character.id
          Result.new(success?: false, errors: ["You can only cancel your own applications"])
        elsif !application.open?
          Result.new(success?: false, errors: ["This application cannot be cancelled"])
        else
          application.update!(status: :cancelled)
          ActiveRecord.after_all_transactions_commit do
            broadcast_application_cancelled(application)
          end

          Result.new(success?: true, application: application)
        end
      end
    end

    private

    attr_reader :publisher, :logger

    def application_creation_error(character, room)
      return "This arena room is unavailable" unless room.accessible_by?(character)
      return "You are already in an active fight" if character_has_active_match?(character)
      return "You already have an active fight application" if character_has_active_application?(character)
      return "Arena room is full" unless room.has_capacity?
      return "Recover before fighting: minimum 50% HP" unless ArenaApplication.new.character_hp_sufficient?(character)

      nil
    end

    def application_acceptance_error(application, acceptor, room)
      return "You cannot accept this application" unless application.acceptable_by?(acceptor)
      return "Applicant can no longer access this arena room" unless room.accessible_by?(application.applicant)
      return "You are already in an active fight" if character_has_active_match?(acceptor)
      return "You already have an active fight application" if character_has_active_application?(acceptor)
      return "Applicant is already in an active fight" if character_has_active_match?(application.applicant)
      return "Applicant must recover before fighting" unless application.character_hp_sufficient?(application.applicant)
      equipment_error = EquipmentRule.new(application.fight_kind).rejection_reason(application.applicant)
      return equipment_error if equipment_error
      return "Arena room is full" unless room.has_capacity?

      nil
    end

    def character_has_active_application?(character)
      character.waiting_arena_application.present? || ArenaApplication.active.exists?(applicant: character)
    end

    def character_has_active_match?(character)
      character.in_combat? || character.unfinished_arena_result.present? || character.arena_participations
        .joins(:arena_match)
        .merge(ArenaMatch.active)
        .exists?
    end

    def lock_characters!(*characters)
      ids = characters.compact.map(&:id).uniq.sort
      Character.where(id: ids).order(:id).lock.load
      characters.compact.each(&:reload)
    end

    def create_match_from_applications(application, acceptor)
      match = ArenaMatch.create!(
        arena_room: application.arena_room,
        match_type: application.fight_type,
        status: :pending,
        turn_timeout_seconds: application.timeout_seconds,
        trauma_percent: application.trauma_percent,
        metadata: {
          fight_kind: application.fight_kind,
          duel_applicant_id: application.applicant_id,
          fight_timeout_seconds: 300,
          physical_only: true
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
      match_metadata = {
        fight_kind: application.fight_kind,
        physical_only: true,
        fight_timeout_seconds: 300,
        is_npc_fight: true,
        npc_template_id: npc.id,
        npc_name: npc.name,
        npc_ai_behavior: npc.ai_behavior
      }
      combat_profile = npc.metadata.to_h["combat_profile"]
      match_metadata["combat_profile"] = combat_profile if combat_profile.present?

      match = ArenaMatch.create!(
        arena_room: application.arena_room,
        match_type: application.fight_type,
        status: :pending,
        turn_timeout_seconds: application.timeout_seconds,
        trauma_percent: application.trauma_percent,
        metadata: match_metadata
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

    def enqueue_application_deadline(application)
      ApplicationDeadlineJob.set(wait_until: application.expires_at).perform_later(application.id)
    rescue StandardError => error
      logger.error("[Arena::ApplicationHandler] application_deadline_enqueue_failed application_id=#{application.id} error=#{error.class}")
    end

    def broadcast_new_application(application)
      publisher.publish(
        channel: "arena:room:#{application.arena_room_id}",
        payload: {
          type: "new_application",
          application: application_payload(application)
        }
      )
    end

    def broadcast_match_created(match, application)
      # Get all participant character IDs for client-side participant detection
      participant_character_ids = match.arena_participations.players.map(&:character_id)
      acceptor_application_id = application.matched_with&.id

      # Broadcast to room - notifies all users viewing the room
      publisher.publish(
        channel: "arena:room:#{application.arena_room_id}",
        payload: {
          type: "match_created",
          match_id: match.id,
          application_id: application.id,
          acceptor_application_id: acceptor_application_id,
          participant_ids: participant_character_ids,
          countdown: 0,
          redirect_url: "/arena_matches/#{match.id}"
        }
      )
    end

    def broadcast_npc_match_created(match, application, acceptor)
      # Notify room that application was accepted
      publisher.publish(
        channel: "arena:room:#{application.arena_room_id}",
        payload: {
          type: "npc_match_created",
          match_id: match.id,
          application_id: application.id,
          countdown: 0,
          redirect_url: "/arena_matches/#{match.id}",
          npc_name: application.npc_template&.name,
          player_name: acceptor.name
        }
      )
    end

    def broadcast_application_cancelled(application)
      publisher.publish(
        channel: "arena:room:#{application.arena_room_id}",
        payload: {
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
        expires_at: application.expires_at&.iso8601,
        expires_in: application.time_until_expiration
      }

      # Add NPC-specific fields
      if application.npc_application?
        payload.merge!(
          is_npc: true,
          npc_avatar: application.npc_template&.avatar_emoji
        )
      end

      payload
    end
  end
end
