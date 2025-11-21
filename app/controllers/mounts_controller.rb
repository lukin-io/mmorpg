# frozen_string_literal: true

class MountsController < ApplicationController
  def index
    @mounts = policy_scope(Mount).where(user: current_user)
  end

  def create
    mount = current_user.mounts.new(mount_params)
    authorize mount
    if mount.save
      redirect_to mounts_path, notice: "Mount added."
    else
      @mounts = policy_scope(Mount).where(user: current_user)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def mount_params
    params.require(:mount).permit(:name, :mount_type, :speed_bonus)
  end
end

