# frozen_string_literal: true

module Characters
  # Quotes or completes a same-cell treatment. Ordered character locks serialize
  # movement, inventory and wallet changes; acceptance rechecks all prerequisites.
  # Completion atomically heals, spends one bag use, transfers NV, records the
  # outcome and publishes durable personal events. A completed retry is inert.
  class TreatInjury
    class Unavailable < StandardError; end
    MAX_PRICE = {"light" => 80, "medium" => 150, "heavy" => 500, "combat" => 7000}.freeze

    def initialize(healer:, injury:, bag: nil, clock: -> { Time.current })
      @healer, @injury, @bag, @clock = healer, injury, bag, clock
    end

    def request!(price:)
      amount = Integer(price, exception: false)
      raise Unavailable, "Invalid treatment price" unless amount && amount.between?(0, MAX_PRICE.fetch(@injury.severity))

      with_characters_locked do
        validate!
        treatment = @injury.injury_treatments.find_by(healer: @healer, status: "pending")
        if treatment && treatment.expires_at <= @clock.call
          treatment.update!(status: "declined")
          treatment = nil
        end
        treatment ||= @injury.injury_treatments.create!(healer: @healer, inventory_item: @bag,
          price: amount, expires_at: @clock.call + 5.minutes)
        complete!(treatment) if treatment.price.zero?
        notify_request!(treatment) if treatment.status == "pending"
        treatment
      end
    end

    def accept!(treatment:, patient:)
      raise Unavailable, "This treatment request belongs to another patient" unless patient.id == @injury.character_id && treatment.character_injury_id == @injury.id && treatment.healer_id == @healer.id

      with_characters_locked do
        treatment.lock!
        return treatment if treatment.status == "completed"
        raise Unavailable, "Treatment request has expired" unless treatment.status == "pending" && treatment.expires_at > @clock.call

        @bag = treatment.inventory_item
        validate!
        complete!(treatment)
        treatment
      end
    end

    private

    def with_characters_locked(&block)
      Character.transaction do
        Character.where(id: [@healer.id, @injury.character_id]).order(:id).lock.load
        @healer.reload
        @injury.lock!
        @patient = @injury.character.reload
        block.call
      end
    end

    def validate!
      raise Unavailable, "The injury has already healed" unless @injury.active?(at: @clock.call)
      raise Unavailable, "Treatment is unavailable during combat" if [@healer, @patient].any? { |c| c.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists? }
      positions = [@healer.position, @patient.position]
      raise Unavailable, "Doctor and patient must be on the same cell" unless positions.all? && positions.map { |p| [p.zone_id, p.x, p.y] }.uniq.one?
      raise Unavailable, "Finish moving before treatment" if MovementCommand.moving.where(character_id: [@healer.id, @patient.id]).exists?
      raise Unavailable, "The Healer perk is required" unless @healer.owns_perk?(:healer)
      raise Unavailable, "An active Doctor license is required" unless @healer.character_licenses.where(kind: "doctor").active_at(@clock.call).exists?
      raise Unavailable, "Combat injuries cannot be self-treated" if @injury.severity == "combat" && @healer.id == @patient.id
      @bag&.lock!
      raise Unavailable, "A matching usable healer bag is required" unless @bag && @bag.inventory.character_id == @healer.id && @bag.effect_modifiers["heals_injury"] == @injury.severity
      requirements = Game::Inventory::RequirementChecker.call(character: @healer, item: @bag)
      raise Unavailable, requirements[:error] unless requirements[:allowed]
    end

    def complete!(treatment)
      if treatment.price.positive?
        patient_wallet = @patient.user.currency_wallet
        healer_wallet = @healer.user.currency_wallet
        raise Unavailable, "Not enough NV" unless patient_wallet && healer_wallet

        CurrencyWallet.where(id: [patient_wallet.id, healer_wallet.id]).order(:id).lock.load
        raise Unavailable, "Not enough NV" if patient_wallet.reload.nv_balance < treatment.price

        patient_wallet.adjust!(amount: -treatment.price, reason: "medical.treatment", metadata: {treatment_id: treatment.id})
        healer_wallet.adjust!(amount: treatment.price, reason: "medical.treatment", metadata: {treatment_id: treatment.id})
      end
      @bag.decrement_durability!
      @injury.update!(healed_at: @clock.call)
      treatment.update!(status: "completed")
      [@patient, @healer].uniq(&:id).each do |character|
        Chat::EventPublisher.new.system_information!(recipient: character.user,
          body: "#{@healer.name} healed #{@patient.name}'s #{@injury.severity} injury «#{@injury.name}».",
          event_key: "treatment:#{treatment.id}:completed:#{character.id}")
      end
    end

    def notify_request!(treatment)
      Chat::EventPublisher.new.system_information!(recipient: @patient.user,
        body: "#{@healer.name} offers treatment for #{treatment.price} NV. Open Medical care to accept.",
        event_key: "treatment:#{treatment.id}:requested")
    end
  end
end
