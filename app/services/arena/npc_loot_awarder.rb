# frozen_string_literal: true

module Arena
  # Resolves and persists one NPC participant's typed loot table exactly once.
  #
  # Item ownership and NV balances are committed in the same transaction as the
  # participant processing marker and player-facing GameEvent projection. The
  # marker, not the presentation event, is the retry authority.
  class NpcLootAwarder
    class InvalidEntryError < StandardError; end
    class InvalidParticipantError < StandardError; end

    Award = Data.define(
      :kind,
      :entry_index,
      :event_key,
      :item_template,
      :quantity,
      :currency,
      :amount,
      :currency_transaction_id
    ) do
      def item?
        kind == "item"
      end

      def currency?
        kind == "currency"
      end

      def description
        if item?
          suffix = quantity > 1 ? " x#{quantity}" : ""
          "Item «#{item_template.name}»#{suffix}"
        else
          "Funds «#{amount} #{currency}»"
        end
      end

      def metadata
        if item?
          {
            "kind" => kind,
            "entry_index" => entry_index,
            "event_key" => event_key,
            "item_template_id" => item_template.id,
            "item_key" => item_template.key,
            "item_name" => item_template.name,
            "quantity" => quantity
          }
        else
          {
            "kind" => kind,
            "entry_index" => entry_index,
            "event_key" => event_key,
            "currency" => currency,
            "amount" => amount,
            "currency_transaction_id" => currency_transaction_id
          }
        end
      end
    end

    Failure = Data.define(:entry_index, :message) do
      def metadata
        {"entry_index" => entry_index, "message" => message}
      end
    end

    Result = Data.define(:awards, :failures, :already_processed) do
      def already_processed?
        already_processed
      end
    end

    def initialize(
      match:,
      npc_participation:,
      character:,
      rng:,
      event_publisher: Chat::EventPublisher.new,
      clock: -> { Time.current }
    )
      @match = match
      @npc_participation = npc_participation
      @character = character
      @rng = rng
      @event_publisher = event_publisher
      @clock = clock
    end

    def call
      ApplicationRecord.transaction do
        npc_participation.lock!
        validate_npc_participation!
        participation = player_participation
        raise InvalidParticipantError, "Loot recipient must participate in the match" unless participation

        participation.lock!

        if loot_already_processed?
          Result.new(awards: [], failures: [], already_processed: true)
        else
          process_loot_table
        end
      end
    end

    private

    attr_reader :match, :npc_participation, :character, :rng, :event_publisher, :clock

    def process_loot_table
      awards = []
      failures = []

      Array(npc_participation.npc_template.loot_table).each_with_index do |raw_entry, entry_index|
        entry = normalize_entry(raw_entry)
        next unless roll_succeeds?(entry)

        awards << award_entry(entry, entry_index)
      rescue Game::Inventory::Manager::CapacityExceededError, InvalidEntryError => e
        failures << Failure.new(entry_index:, message: e.message)
      end

      record_player_awards!(awards)
      publish_awards!(awards)
      record_resolution!(awards, failures)

      Result.new(awards:, failures:, already_processed: false)
    end

    def roll_succeeds?(entry)
      chance = Float(entry.fetch(:chance, 1.0), exception: false)
      raise InvalidEntryError, "Loot chance must be between 0 and 100" unless chance

      chance_percent = chance <= 1 ? chance * 100 : chance
      unless chance_percent.between?(0, 100)
        raise InvalidEntryError, "Loot chance must be between 0 and 100"
      end

      rng.rand(100) < chance_percent
    end

    def normalize_entry(raw_entry)
      unless raw_entry.respond_to?(:each_pair)
        raise InvalidEntryError, "Loot entry must be an object"
      end

      raw_entry.to_h.with_indifferent_access
    end

    def award_entry(entry, entry_index)
      case loot_kind(entry)
      when "item"
        award_item(entry, entry_index)
      when "currency"
        award_currency(entry, entry_index)
      else
        raise InvalidEntryError, "Unsupported loot kind: #{loot_kind(entry)}"
      end
    end

    def loot_kind(entry)
      (entry[:kind].presence || "item").to_s
    end

    def award_item(entry, entry_index)
      item_template = find_item_template!(entry)
      quantity = positive_integer(entry.fetch(:quantity, 1), field: "Item quantity")
      event_key = event_key_for(entry_index)

      Game::Inventory::Manager.new(inventory: character.inventory).add_item!(
        item_template:,
        quantity:
      )

      Award.new(
        kind: "item",
        entry_index:,
        event_key:,
        item_template:,
        quantity:,
        currency: nil,
        amount: nil,
        currency_transaction_id: nil
      )
    end

    def award_currency(entry, entry_index)
      amount = positive_integer(entry[:amount], field: "Currency amount")
      currency = entry.fetch(:currency, "NV").to_s.upcase
      raise InvalidEntryError, "Unsupported loot currency: #{currency}" unless currency == "NV"

      event_key = event_key_for(entry_index)
      wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
      wallet.adjust!(
        amount:,
        reason: "combat.npc_loot",
        metadata: source_payload(entry_index).merge("event_key" => event_key)
      )
      transaction = wallet.currency_transactions.order(:id).last!

      Award.new(
        kind: "currency",
        entry_index:,
        event_key:,
        item_template: nil,
        quantity: nil,
        currency:,
        amount:,
        currency_transaction_id: transaction.id
      )
    end

    def find_item_template!(entry)
      key = entry[:item_key] || entry[:item] || entry[:key]
      name = entry[:item_name] || entry[:name] || entry[:source_name]
      template = ItemTemplate.find_by(key:) if key.present?
      template ||= ItemTemplate.find_by(name:) if name.present?
      return template if template

      identity = key.presence || name.presence || "missing"
      raise InvalidEntryError, "Loot item template not found: #{identity}"
    end

    def positive_integer(value, field:)
      amount = Integer(value, exception: false)
      raise InvalidEntryError, "#{field} must be a positive integer" unless amount&.positive?

      amount
    end

    def publish_awards!(awards)
      recipient = character.user
      return unless recipient

      awards.each do |award|
        payload = source_payload(award.entry_index)

        if award.item?
          event_publisher.item_found!(
            recipient:,
            item_name: award.item_template.name,
            quantity: award.quantity,
            event_key: award.event_key,
            payload: payload.merge(item_template_id: award.item_template.id)
          )
        else
          event_publisher.money_found!(
            recipient:,
            amount: award.amount,
            currency: award.currency,
            event_key: award.event_key,
            payload: payload.merge(currency_transaction_id: award.currency_transaction_id)
          )
        end
      end
    end

    def record_player_awards!(awards)
      participation = player_participation
      return unless participation

      metadata = participation.metadata.to_h
      awarded_at = clock.call.iso8601
      award_metadata = awards.map do |award|
        award.metadata.merge(
          "npc_key" => npc_participation.npc_template.npc_key,
          "awarded_at" => awarded_at
        )
      end
      metadata["loot_awards"] = Array(metadata["loot_awards"]) + award_metadata
      metadata["loot_drops"] = Array(metadata["loot_drops"]) + award_metadata.select do |award|
        award["kind"] == "item"
      end
      participation.update!(metadata:)
    end

    def record_resolution!(awards, failures)
      metadata = npc_participation.metadata.to_h
      metadata["loot_resolution"] = {
        "processed_at" => clock.call.iso8601,
        "character_id" => character.id,
        "awards" => awards.map(&:metadata),
        "failures" => failures.map(&:metadata)
      }
      npc_participation.update!(metadata:)
    end

    def loot_already_processed?
      npc_participation.metadata.to_h.key?("loot_resolution")
    end

    def validate_npc_participation!
      return if npc_participation.arena_match_id == match.id && npc_participation.npc?

      raise InvalidParticipantError, "Loot source must be an NPC in the match"
    end

    def player_participation
      @player_participation ||= match.arena_participations.find_by(character:)
    end

    def event_key_for(entry_index)
      "arena-match:#{match.id}:npc-participation:#{npc_participation.id}:" \
        "loot:#{entry_index}:user:#{character.user_id}"
    end

    def source_payload(entry_index)
      {
        arena_match_id: match.id,
        character_id: character.id,
        npc_participation_id: npc_participation.id,
        npc_template_id: npc_participation.npc_template_id,
        loot_entry_index: entry_index
      }
    end
  end
end
