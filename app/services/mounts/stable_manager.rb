# frozen_string_literal: true

module Mounts
  # StableManager handles unlocking stable slots, assigning mounts, and summoning/despawning.
  #
  # Usage:
  #   Mounts::StableManager.new(user: current_user).unlock_slot!(slot_index: 1)
  #   Mounts::StableManager.new(user: current_user).summon!(slot_index: 0)
  class StableManager
    SLOT_PRICING = Hash.new do |hash, index|
      hash[index] = {currency: :gold, amount: 1_000 * (index + 1)}
    end.merge(
      2 => {currency: :premium_tokens, amount: 10},
      3 => {currency: :premium_tokens, amount: 25}
    )

    def initialize(user:, wallet_service: Economy::WalletService)
      @user = user
      @wallet_service = wallet_service
    end

    def unlock_slot!(slot_index:)
      slot = fetch_slot(slot_index)
      raise StandardError, "Slot already unlocked" unless slot.locked?

      charge_for_slot!(slot_index)
      slot.update!(status: :unlocked, unlocked_at: Time.current)
      slot
    end

    def assign_mount!(slot_index:, mount:)
      slot = fetch_slot(slot_index)
      raise Pundit::NotAuthorizedError unless mount.user_id == user.id
      raise StandardError, "Slot locked" if slot.locked?

      ApplicationRecord.transaction do
        slot.update!(current_mount: mount, status: :active)
        mount.update!(mount_stable_slot: slot)
      end
      slot
    end

    def summon!(slot_index:)
      slot = fetch_slot(slot_index)
      mount = slot.current_mount or raise StandardError, "No mount assigned"

      Mount.transaction do
        user.mounts.where(summon_state: :summoned).update_all(summon_state: :stabled)
        mount.update!(summon_state: :summoned)
      end
      mount
    end

    private

    attr_reader :user, :wallet_service

    def fetch_slot(slot_index)
      user.mount_stable_slots.find_or_create_by!(slot_index:) do |slot|
        slot.status = :locked
      end
    end

    def charge_for_slot!(slot_index)
      pricing = SLOT_PRICING[slot_index]
      wallet = user.currency_wallet || user.create_currency_wallet!
      wallet_service.new(wallet: wallet).sink!(
        currency: pricing[:currency],
        amount: pricing[:amount],
        sink_reason: :stable_unlock,
        metadata: {slot_index: slot_index}
      )
    end
  end
end
