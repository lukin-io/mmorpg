# frozen_string_literal: true

module Arena
  # Builds both sides of one posted application. Room -> application -> sorted
  # characters is the mutation lock order. Joining reserves a roster place;
  # the waiting deadline starts the same CombatProcessor used by Duels/PvE.
  # Missing opponents expire the application without creating a fight or rewards.
  class GroupAssembly
    Result = Struct.new(:success?, :application, :match, :errors, keyword_init: true)

    def initialize(publisher: RealtimePublisher.new, clock: -> { Time.current })
      @publisher, @clock = publisher, clock
    end

    def join(application:, character:, team:)
      mutate(application, [character]) do
        error = application.group_rejection_reason(character, team:)
        error ||= "You already have an active fight application" if character.waiting_arena_application
        error ||= "You are already in combat" if active_match?(character)
        if error
          Result.new(success?: false, application:, errors: [error])
        else
          application.arena_application_memberships.create!(character:, team:)
          publish_after_commit(application)
          Result.new(success?: true, application:)
        end
      end
    rescue ActiveRecord::RecordInvalid => error
      Result.new(success?: false, application:, errors: [error.message])
    end

    def withdraw(application:, character:)
      mutate(application, [character]) do
        membership = application.arena_application_memberships.find_by(character:)
        if !application.open? || !membership
          Result.new(success?: false, application:, errors: ["You have no open place in this application"])
        else
          if application.applicant_id == character.id
            application.update!(status: :cancelled)
          else
            membership.destroy!
          end
          publish_after_commit(application)
          Result.new(success?: true, application:)
        end
      end
    end

    # Safe for a delayed job and a room-refresh recovery. Early/duplicate jobs
    # are no-ops. Revalidates every member before constructing the shared match.
    def settle(application:)
      application.arena_room.with_lock do
        application.lock!
        return unless application.open? && application.deadline_passed?(now: @clock.call)

        memberships = application.arena_application_memberships.includes(:character).order(:character_id).to_a
        characters = Character.where(id: memberships.map(&:character_id)).order(:id).lock.index_by(&:id)
        memberships.each { |entry| entry.character = characters.fetch(entry.character_id) }
        unless ready?(application, memberships)
          application.update!(status: :expired)
          publish_after_commit(application)
          return
        end

        match = ArenaMatch.create!(arena_room: application.arena_room, match_type: :team_battle,
          status: :pending, turn_timeout_seconds: application.timeout_seconds,
          trauma_percent: application.trauma_percent,
          metadata: {fight_kind: application.fight_kind, fight_timeout_seconds: 300, physical_only: true})
        memberships.each do |entry|
          match.arena_participations.create!(character: entry.character, user: entry.character.user,
            team: entry.team, joined_at: @clock.call)
        end
        application.update!(status: :matched, arena_match: match, matched_at: @clock.call, starts_at: @clock.call)
        CombatProcessor.new(match).start_match
        publish_after_commit(application, match:)
        match
      end
    end

    private

    def mutate(application, characters)
      application.arena_room.with_lock do
        application.lock!
        Character.where(id: characters.map(&:id)).order(:id).lock.load
        characters.each(&:reload)
        application.arena_application_memberships.reset
        yield
      end
    end

    def active_match?(character)
      character.in_combat? || character.unfinished_arena_result.present? || character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
    end

    def ready?(application, memberships)
      return false unless memberships.map(&:team).uniq.sort == %w[a b]
      return false unless application.arena_room.has_capacity?
      return false unless memberships.group_by(&:team).all? { |team, entries| entries.size <= application.side_capacity(team) }

      memberships.all? do |entry|
        character = entry.character
        application.arena_room.accessible_by?(character) && !active_match?(character) &&
          application.side_level_range(entry.team).cover?(character.level) &&
          application.character_hp_sufficient?(character) &&
          EquipmentRule.new(application.fight_kind).rejection_reason(character).nil? &&
          (!(application.alignment_vs_alignment? || application.alignment_vs_all?) ||
            application.group_alignment_matches?(character, team: entry.team))
      end
    end

    def publish_after_commit(application, match: nil)
      ActiveRecord.after_all_transactions_commit do
        @publisher.publish(channel: "arena:room:#{application.arena_room_id}", payload: {
          type: match ? "match_created" : "application_changed", application_id: application.id,
          participant_ids: application.arena_application_memberships.pluck(:character_id),
          match_id: match&.id, countdown: 0
        })
      end
    end
  end
end
