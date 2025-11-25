class MountsController < ApplicationController
  before_action :set_manager, only: [:unlock_slot, :assign_to_slot, :summon]
  before_action :set_mount, only: [:assign_to_slot, :summon]

  def index
    @mounts = policy_scope(Mount).where(user: current_user)
    @stable_slots = current_user.mount_stable_slots.order(:slot_index)
  end

  def create
    mount = current_user.mounts.new(mount_params)
    authorize mount
    if mount.save
      redirect_to mounts_path, notice: "Mount added."
    else
      @mounts = policy_scope(Mount).where(user: current_user)
      @stable_slots = current_user.mount_stable_slots.order(:slot_index)
      render :index, status: :unprocessable_entity
    end
  end

  def unlock_slot
    authorize Mount, :create?
    @manager.unlock_slot!(slot_index: slot_params[:slot_index].to_i)
    redirect_to mounts_path, notice: "Stable slot unlocked."
  rescue Economy::WalletService::InsufficientFundsError
    redirect_to mounts_path, alert: "Insufficient funds."
  end

  def assign_to_slot
    @manager.assign_mount!(slot_index: slot_params[:slot_index].to_i, mount: @mount)
    redirect_to mounts_path, notice: "Mount assigned to slot."
  end

  def summon
    @manager.summon!(slot_index: slot_params[:slot_index].to_i)
    redirect_to mounts_path, notice: "#{@mount.name} summoned."
  end

  private

  def set_manager
    @manager = Mounts::StableManager.new(user: current_user)
  end

  def set_mount
    @mount = authorize current_user.mounts.find(params[:id])
  end

  def mount_params
    params.require(:mount).permit(:name, :mount_type, :speed_bonus, :faction_key, :rarity, :cosmetic_variant)
  end

  def slot_params
    params.require(:slot).permit(:slot_index)
  end
end
# frozen_string_literal: true
