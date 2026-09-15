# frozen_string_literal: true

module Game
  module Inventory
    # Inventory entry adapter for the shared combat engine. A short-lived offer
    # binds an owned scroll and its location. Successful use atomically spends
    # one charge, creates/joins the match, and records an auditable receipt.
    # Existing match -> ordered characters -> offer -> inventories/items is the
    # lock order; a changed target fight is rejected before acquiring new locks.
    class AttackScroll
      class Unavailable < StandardError; end

      RULES = {
        "duel_permit_i" => {title: "Ordinary attack", trauma: 10, unarmed: false},
        "fist_attack" => {title: "Fist attack", trauma: 80, unarmed: true}
      }.freeze
      LEVEL_DIFFERENCE = 3

      def self.definition(template)
        RULES[template.key] if template.consumable?
      end

      def initialize(character:, clock: -> { Time.current })
        @character, @clock = character, clock
      end

      # Returns the reusable capability for the Inventory target form. Opening
      # or cancelling the form never spends a charge or starts a fight.
      def offer_for(item:)
        @character.with_lock do
          raise Unavailable, "This scroll is unavailable" unless item.inventory.character_id == @character.id && self.class.definition(item.item_template)
          validate_actor!(@character)
          requirements = RequirementChecker.call(character: @character, item:)
          raise Unavailable, requirements[:error] unless requirements[:allowed]

          position = @character.position
          context = location_key(@character)
          candidates = WorldActionOffer.offered.where(character: @character, action_type: "scroll_attack")
          offer = candidates.where(target: item).where("expires_at > ?", @clock.call)
            .where("metadata ->> 'location_key' = ?", context).order(:id).first
          offer ||= candidates.create!(zone: position.zone, x: position.x, y: position.y,
            target: item, action_key: SecureRandom.hex(16), expires_at: @clock.call + WorldActionOffer::OFFER_TTL,
            metadata: {"location_key" => context, "item_key" => item.item_template.key})
          candidates.where.not(id: offer.id).update_all(status: :cancelled, updated_at: @clock.call)
          offer
        end
      end

      # Inputs are the server-issued action key and a nickname, never fight
      # rules, coordinates, equipment flags, trauma, or a client match id.
      # Returns ArenaMatch. Failed validation leaves the offer and item intact;
      # a completed retry returns its original match even after the item is gone.
      def call(action_key:, target_name:)
        offer = WorldActionOffer.find_by(character: @character, action_type: "scroll_attack", action_key: action_key.to_s)
        raise Unavailable, "Reopen the scroll's Use form" unless offer
        return ArenaMatch.find(offer.metadata.fetch("match_id")) if offer.completed?

        target = Character.where("LOWER(name) = ?", target_name.to_s.strip.downcase).first
        raise Unavailable, "Player not found" unless target
        target_match = active_match(target)

        ApplicationRecord.transaction do
          target_match&.lock!
          players = Character.where(id: [@character.id, target.id]).order(:id).lock.index_by(&:id)
          @character = players.fetch(@character.id)
          target = players.fetch(target.id)
          offer.lock!
          next ArenaMatch.find(offer.metadata.fetch("match_id")) if offer.completed?

          validate_actor!(@character)
          validate_target!(target, target_match)
          ::Inventory.where(character_id: players.keys).order(:id).lock.load
          item = @character.inventory.inventory_items.lock.find_by(id: offer.target_id)
          rules = item && self.class.definition(item.item_template)
          raise Unavailable, "This scroll is unavailable" unless item && rules && offer.target_type == "InventoryItem"
          requirements = RequirementChecker.call(character: @character, item:)
          raise Unavailable, requirements[:error] unless requirements[:allowed]
          raise Unavailable, "The scroll has changed; reopen Use" unless offer.metadata["item_key"] == item.item_template.key
          raise Unavailable, "Reopen the scroll's Use form at your current location" unless offer.offered? &&
            offer.expires_at > @clock.call && offer.matches_position?(@character.position) &&
            offer.metadata["location_key"] == location_key(@character)

          match = if target_match
            join_match!(target_match, target, rules)
          else
            create_match!(target, rules)
          end
          before = {"quantity" => item.quantity, "durability" => item.current_durability}
          Manager.consume_item_unit!(item)
          offer.update!(status: :completed, accepted_at: @clock.call, completed_at: @clock.call,
            metadata: offer.metadata.merge("match_id" => match.id, "target_character_id" => target.id,
              "item_before" => before, "item_remaining" => item.destroyed? ? 0 : item.quantity))
          publish_entry!(match, target, item.item_template, offer)
          match
        end
      rescue ActiveRecord::RecordNotFound
        raise Unavailable, "The scroll or player is no longer available"
      end

      private

      def active_match(character)
        character.arena_participations.joins(:arena_match).merge(ArenaMatch.active)
          .order(:id).first&.arena_match
      end

      def location_key(character)
        Game::World::Presence.new(character:).context_key
      end

      def validate_actor!(character)
        validate_ground!(character)
        raise Unavailable, "Finish your current fight first" if character.in_combat? || active_match(character) || character.unfinished_arena_result
        raise Unavailable, "Withdraw your Arena application first" if character.waiting_arena_application
        raise Unavailable, "A combat injury prevents using Inventory" if character.character_injuries.active_at(@clock.call).where(severity: "combat").exists?
        raise Unavailable, "Finish the local action first" if Game::World::LocalActionState.new(character:, clock: @clock).call
      end

      def validate_ground!(character)
        raise Unavailable, "Player location is unavailable" unless character.position&.active?
        raise Unavailable, "Disembark before fighting on the ground" if character.active_airship_journey
        raise Unavailable, "Finish moving before fighting" if MovementCommand.moving.where(character:).exists?
        raise Unavailable, "The player must recover first" unless character.current_hp.positive?
      end

      def validate_target!(target, expected_match)
        raise Unavailable, "You cannot attack yourself" if target.id == @character.id || target.user_id == @character.user_id
        validate_ground!(target)
        raise Unavailable, "Player is offline" unless target.user.character&.id == target.id &&
          target.user.user_sessions.recent(at: @clock.call).exists?
        raise Unavailable, "The player must be in the same location" unless location_key(@character) == location_key(target)
        # The live 17 -> 5 attempts returned this generic failure for both
        # variants; the inclusive limit itself remains the wiki's rule.
        raise Unavailable, "Error using item. Scroll use failed." if (@character.level - target.level).abs > LEVEL_DIFFERENCE
        raise Unavailable, "The target's fight changed; try again" unless active_match(target)&.id == expected_match&.id
        raise Unavailable, "The player is waiting for an Arena fight" if target.waiting_arena_application
        raise Unavailable, "The player must finish the previous fight" if target.unfinished_arena_result
        raise Unavailable, "The player's combat state is unavailable" if target.in_combat? && !expected_match
      end

      def create_match!(target, rules)
        if rules.fetch(:unarmed)
          [@character, target].each do |player|
            EquipmentService.new(character: player).unequip_all! if player.inventory
            player.reload
            player.update!(current_hp: [player.current_hp, player.effective_max_hp].min,
              current_mp: [player.current_mp, player.effective_max_mp].min)
          end
        end
        match = ArenaMatch.create!(zone: @character.position.zone, match_type: :duel, status: :pending,
          turn_timeout_seconds: 300, trauma_percent: rules.fetch(:trauma),
          metadata: {source: "scroll_pvp", physical_only: true, fight_timeout_seconds: 300,
            fight_kind: rules.fetch(:unarmed) ? "no_weapons" : "free", location_key: location_key(@character)})
        add_participant!(match, @character, "a", scroll_entry: true)
        add_participant!(match, target, "b")
        Arena::CombatProcessor.new(match).start_match
        interrupt_local_actions!([@character, target])
        match
      end

      def join_match!(match, target, rules)
        raise Unavailable, "This fight is unavailable for intervention" unless match.live? && !match.stale? && match.metadata.to_h["fight_kind"] != "closed"
        raise Unavailable, "Fist Attack requires a player outside combat" if rules.fetch(:unarmed)
        participation = match.arena_participations.find_by!(character: target)
        raise Unavailable, "Defeated players cannot be attacked again in this fight" unless participation.combat_alive?
        error = Arena::EquipmentRule.new(match.metadata.to_h.fetch("fight_kind", "free")).rejection_reason(@character)
        raise Unavailable, error if error
        raise Unavailable, "This fight is full" if match.arena_participations.count >= 60

        add_participant!(match, @character, participation.team == "a" ? "b" : "a", scroll_entry: true)
        match.update!(match_type: :team_battle)
        @character.update!(in_combat: true, last_combat_at: @clock.call)
        Arena::CombatProcessor.new(match).prepare_combat_profiles!
        interrupt_local_actions!([@character])
        ActiveRecord.after_all_transactions_commit do
          Arena::CombatBroadcaster.new(match).broadcast_state_refresh(reason: :participant_joined)
        end
        match
      end

      def add_participant!(match, player, team, scroll_entry: false)
        match.arena_participations.create!(character: player, user: player.user, team:, joined_at: @clock.call,
          metadata: scroll_entry ? {"scroll_entry" => true} : {})
      end

      def interrupt_local_actions!(players)
        players.each do |player|
          player.reload
          player.update!(metadata: player.metadata.to_h.except(Game::World::PassiveEncounterCheck::SCHEDULE_METADATA_KEY))
        end
        WorldActionOffer.timed_local_actions.where(character: players).update_all(status: :cancelled, updated_at: @clock.call)
      end

      def publish_entry!(match, target, template, offer)
        body = "#{@character.name} used #{template.name} to attack #{target.name}."
        Arena::CombatLogRecorder.new(match).record!(entry_type: "system", actor: @character, target:,
          description: body, payload: {scroll_offer_id: offer.id, item_key: template.key})
        [@character, target].each do |player|
          Chat::EventPublisher.new.system_information!(recipient: player.user, body:,
            event_key: "scroll:#{offer.id}:entry:#{player.id}")
        end
      end
    end
  end
end
