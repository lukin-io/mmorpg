# frozen_string_literal: true

module Premium
  # ArtifactStore redeems premium-only convenience items (teleports, storage, XP boosts).
  class ArtifactStore
    Artifact = Struct.new(:cost, :description, :effect)

    ARTIFACTS = {
      teleport_scroll: Artifact.new(
        75,
        "Teleport to any unlocked city",
        lambda do |character:, metadata:|
          zone = Zone.find(metadata.fetch(:zone_id))
          Game::Movement::TeleportService.new(
            character:,
            zone: zone,
            x: metadata.fetch(:x),
            y: metadata.fetch(:y)
          ).call
        end
      ),
      storage_upgrade: Artifact.new(
        50,
        "Permanent +5 slot/+50 weight storage boost",
        lambda do |character:, metadata:|
          Game::Inventory::ExpansionService.new(character:).expand!(
            source: :artifact,
            slot_bonus: metadata[:slot_bonus] || Game::Inventory::ExpansionService::DEFAULT_SLOT_BONUS,
            weight_bonus: metadata[:weight_bonus] || Game::Inventory::ExpansionService::DEFAULT_WEIGHT_BONUS
          )
        end
      ),
      xp_boost: Artifact.new(
        40,
        "Instant experience boost",
        lambda do |character:, metadata:|
          xp = metadata[:xp_amount] || 1_000
          Players::Progression::ExperiencePipeline.new(character:).grant!({"premium" => xp})
        end
      )
    }.freeze

    def initialize(ledger: Payments::PremiumTokenLedger)
      @ledger = ledger
    end

    def purchase!(user:, artifact_key:, character:, metadata: {})
      artifact = ARTIFACTS[artifact_key.to_sym]
      raise ArgumentError, "Unknown artifact #{artifact_key}" unless artifact

      ledger.debit(
        user: user,
        amount: artifact.cost,
        reason: "premium.artifact.#{artifact_key}",
        actor: user,
        metadata: metadata.merge(character_id: character.id)
      )
      artifact.effect.call(character:, metadata:)
    end

    private

    attr_reader :ledger
  end
end
