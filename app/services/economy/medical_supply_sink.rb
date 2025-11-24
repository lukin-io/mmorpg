# frozen_string_literal: true

module Economy
  # MedicalSupplySink charges infirmary fees and depletes crafted medical stock.
  class MedicalSupplySink
    GOLD_FEE = 50
    SILVER_FEE = 100
    SUPPLIES_PER_VISIT = 1

    def initialize(zone:, wallet_service: Economy::WalletService)
      @zone = zone
      @wallet_service = wallet_service
    end

    def consume!(character:)
      return unless character&.user

      wallet = character.user.currency_wallet
      wallet_service.new(wallet: wallet).sink!(
        currency: :gold,
        amount: GOLD_FEE,
        sink_reason: :infirmary,
        metadata: base_metadata(character:)
      )
      wallet_service.new(wallet: wallet).sink!(
        currency: :silver,
        amount: SILVER_FEE,
        sink_reason: :infirmary,
        metadata: base_metadata(character:)
      )
      withdraw_supply!
    rescue Economy::WalletService::InsufficientFundsError
      # If the player cannot pay, we still attempt to consume supply but skip charging.
      withdraw_supply!
    end

    private

    attr_reader :zone, :wallet_service

    def withdraw_supply!
      return unless pool && pool.available_quantity >= SUPPLIES_PER_VISIT

      pool.withdraw!(SUPPLIES_PER_VISIT)
    end

    def pool
      return unless zone

      @pool ||= MedicalSupplyPool.find_by(zone: zone)
    end

    def base_metadata(character:)
      {
        character_id: character.id,
        zone_id: zone&.id
      }
    end
  end
end
