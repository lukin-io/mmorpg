# frozen_string_literal: true

module Game
  module Shop
    # Issues and consumes one-unit Shop capabilities using the existing durable
    # offer records. Offers bind a character, location, action, target and quoted
    # item state. Consumption and the caller's trade commit in one transaction.
    class TradeOffers
      class Unavailable < StandardError; end

      ACTIONS = %w[shop_buy shop_sell].freeze

      def initialize(character:)
        @character = character
      end

      # Returns {buy: {template_id => offer}, sell: {item_id => offer}} for the
      # supplied visible rows. Reads reuse unchanged offers; obsolete Shop
      # offers are cancelled without altering unrelated world capabilities.
      def issue(buy_items: [], sell_items: [])
        character.with_lock do
          context = Location.new(character:).call
          location = context.fingerprint
          account = context.account
          license_rules = LicenseRules.new(character:,
            active_licenses: CharacterLicense.where(character:).active_at(Time.current).to_a)
          position = character.position
          candidates = WorldActionOffer.live.where(character:, action_type: ACTIONS)
            .at_tile(position.zone, position.x, position.y).order(:id).to_a
          issued = {buy: {}, sell: {}}

          {buy: buy_items, sell: sell_items}.each do |action, items|
            items.each do |target|
              next unless account
              next if action == :buy && !target.available_in_shop?
              next if action == :buy && license_rules.purchase_block_reason(target)
              next if action == :sell && (!target.tradable? || target.broken? || !target.valid_sale_durability? || !Catalog.sale_price_for_item(target, trading_skill: LicenseRules.trading_skill(character)).positive?)

              metadata = {"shop_location" => location, "shop_account_id" => account.id, "target_state" => target_state(target)}
              action_type = "shop_#{action}"
              offer = candidates.find do |candidate|
                candidate.action_type == action_type && candidate.target_type == target.class.base_class.name &&
                  candidate.target_id == target.id && candidate.metadata == metadata
              end
              issued[action][target.id] = offer || WorldActionOffer.create!(
                character:, zone: position.zone, x: position.x, y: position.y,
                action_type:, target:, action_key: SecureRandom.hex(16),
                expires_at: WorldActionOffer::OFFER_TTL.from_now, metadata:
              )
            end
          end

          WorldActionOffer.offered.where(character:, action_type: ACTIONS)
            .where.not(id: issued.values.flat_map(&:values).map(&:id))
            .update_all(status: WorldActionOffer.statuses.fetch("cancelled"), updated_at: Time.current)
          issued
        end
      end

      # Holds the character and offer locks while the caller locks its item
      # records, validates the quote, and performs the trade. Exceptions roll
      # back both valuable state and capability consumption, including inside
      # the controller's enclosing character-availability transaction.
      def perform(action_key:, action:, target:)
        ApplicationRecord.transaction(requires_new: true) do
          character.lock!
          context = Location.new(character:).call
          location = context.fingerprint
          account = context.account
          raise Unavailable, "This shop is not trading right now." unless account

          offer = WorldActionOffer.offered.where(character:, action_type: "shop_#{action}", action_key: action_key.to_s).lock.first
          unless offer && !offer.expired? && offer.matches_position?(character.position) &&
              offer.target_type == target.class.base_class.name && offer.target_id == target.id &&
              offer.metadata["shop_location"] == location && offer.metadata["shop_account_id"] == account.id
            raise Unavailable, "Shop action is no longer available. Refresh the shop."
          end

          account.lock!
          yield offer, account
          offer.accept!
          offer.complete!
        end
      end

      # Called only after the trade has locked and reloaded template/inventory
      # state. Stock remains a separate live precondition: another customer's
      # purchase does not change this customer's quoted item or price.
      def validate_target!(offer, target)
        return if offer.metadata["target_state"] == target_state(target)

        raise Unavailable, "This item has changed. Refresh the shop."
      end

      # Lock waits can outlive a capability that was valid on request arrival.
      # Each trade calls this after every existing valuable record is locked,
      # immediately before its first write.
      def validate_deadline!(offer)
        return unless offer.expired?

        raise Unavailable, "Shop action is no longer available. Refresh the shop."
      end

      private

      attr_reader :character

      def target_state(target)
        template = target.is_a?(ItemTemplate) ? target : target.item_template
        state = template.attributes.slice("key", "name", "item_type", "slot", "base_price", "weight", "stack_limit", "durability_max", "requirements", "stat_modifiers")
          .merge("enhancement_rules" => template.enhancement_rules.to_h.except("shop_stock"))
        unless target.is_a?(ItemTemplate)
          state["inventory_item"] = target.attributes.slice("inventory_id", "item_template_id", "quantity", "weight", "equipped", "bound", "equipment_slot", "properties")
          state["trading_skill"] = LicenseRules.trading_skill(character)
        end
        Digest::SHA256.hexdigest(canonical_state(state).to_json)
      end

      def canonical_state(value)
        case value
        when Hash then value.sort.to_h.transform_values { |entry| canonical_state(entry) }
        when Array then value.map { |entry| canonical_state(entry) }
        else value
        end
      end
    end
  end
end
