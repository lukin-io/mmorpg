# frozen_string_literal: true

module Arena
  # Auto-matches compatible arena applications
  # Runs periodically to find and pair waiting applications
  #
  # @example Find and create matches for a room
  #   matchmaker = Arena::Matchmaker.new
  #   matches = matchmaker.find_matches(room: arena_room)
  #
  class Matchmaker
    # Find compatible applications and create matches
    #
    # @param room [ArenaRoom] the room to process
    # @return [Array<ArenaMatch>] created matches
    def find_matches(room:)
      matches = []

      # Group open applications by fight type
      room.arena_applications.open.group_by(&:fight_type).each do |fight_type, applications|
        case fight_type.to_sym
        when :duel
          matches.concat(match_duels(applications))
        when :group
          matches.concat(match_groups(applications))
        when :sacrifice
          matches.concat(match_sacrifice(applications, room))
        end
      end

      matches
    end

    # Check if a character is eligible for an application
    #
    # @param character [Character] the character to check
    # @param application [ArenaApplication] the application to check against
    # @return [Boolean] true if eligible
    def check_eligibility(character, application)
      return false if character.level < (application.team_level_min || 0)
      return false if character.level > (application.team_level_max || 100)
      return false if application.closed_fight? && !application.invited?(character)
      return false if application.faction_restricted? && !application.faction_matches?(character)

      true
    end

    # Expire old applications
    #
    # @return [Integer] count of expired applications
    def expire_stale_applications
      count = 0
      ArenaApplication.expired_and_unprocessed.find_each do |application|
        application.update!(status: :expired)
        broadcast_expiration(application)
        count += 1
      end
      count
    end

    private

    def match_duels(applications)
      matches = []
      matched_ids = Set.new

      # Sort by creation time (FIFO)
      sorted = applications.sort_by(&:created_at)

      sorted.each do |app1|
        next if matched_ids.include?(app1.id)

        # Find compatible opponent
        opponent = sorted.find do |app2|
          next if app2.id == app1.id
          next if matched_ids.include?(app2.id)

          compatible_for_duel?(app1, app2)
        end

        if opponent
          match = create_duel_match(app1, opponent)
          matches << match if match
          matched_ids.add(app1.id)
          matched_ids.add(opponent.id)
        end
      end

      matches
    end

    def match_groups(applications)
      matches = []
      # Group fights need more complex matching logic
      # For now, match applications with compatible team sizes

      grouped = applications.group_by { |a| [a.team_count, a.enemy_count].sort }

      grouped.each do |_sizes, apps|
        next if apps.size < 2

        # Match pairs
        apps.each_slice(2) do |pair|
          next unless pair.size == 2

          match = create_group_match(pair[0], pair[1])
          matches << match if match
        end
      end

      matches
    end

    def match_sacrifice(applications, room)
      # Sacrifice fights start when enough players are waiting
      return [] if applications.size < 3

      # Find applications that have been waiting long enough
      ready = applications.select { |a| a.created_at < 30.seconds.ago }
      return [] if ready.size < 3

      # Create a sacrifice match with all ready participants
      [create_sacrifice_match(ready, room)]
    end

    def compatible_for_duel?(app1, app2)
      # Check fight kind compatibility
      return false unless app1.fight_kind == app2.fight_kind

      # Check level overlap
      range1 = (app1.team_level_min || 0)..(app1.team_level_max || 100)
      range2 = (app2.team_level_min || 0)..(app2.team_level_max || 100)

      # Levels should overlap
      return false unless ranges_overlap?(range1, range2)

      # Check faction compatibility for faction fights
      if app1.faction_restricted? || app2.faction_restricted?
        return app1.applicant.faction_alignment != app2.applicant.faction_alignment
      end

      true
    end

    def ranges_overlap?(r1, r2)
      r1.cover?(r2.first) || r2.cover?(r1.first)
    end

    def create_duel_match(app1, app2)
      handler = Arena::ApplicationHandler.new
      result = handler.accept(application: app1, acceptor: app2.applicant)

      if result.success?
        # Also update app2
        app2.update!(status: :matched, arena_match: result.match, matched_with: app1)
        result.match
      end
    rescue StandardError => e
      Rails.logger.error("Failed to create duel match: #{e.message}")
      nil
    end

    def create_group_match(app1, app2)
      # Similar to duel but for group fights
      create_duel_match(app1, app2)
    end

    def create_sacrifice_match(applications, room)
      match = ArenaMatch.create!(
        arena_room: room,
        arena_season: ArenaSeason.current.first,
        match_type: :sacrifice,
        status: :pending,
        metadata: {
          fight_kind: applications.first.fight_kind,
          timeout_seconds: applications.first.timeout_seconds,
          trauma_percent: applications.first.trauma_percent
        }
      )

      # All participants are on their own team (FFA)
      applications.each_with_index do |app, index|
        ArenaParticipation.create!(
          arena_match: match,
          character: app.applicant,
          user: app.applicant.user,
          team: "player_#{index}",
          joined_at: Time.current
        )

        app.update!(status: :matched, arena_match: match, matched_at: Time.current)
      end

      # Schedule start
      Arena::MatchStarterJob.set(wait: 30.seconds).perform_later(match.id)

      match
    rescue StandardError => e
      Rails.logger.error("Failed to create sacrifice match: #{e.message}")
      nil
    end

    def broadcast_expiration(application)
      ActionCable.server.broadcast(
        "arena:room:#{application.arena_room_id}",
        {
          type: "application_expired",
          application_id: application.id
        }
      )
    end
  end
end
