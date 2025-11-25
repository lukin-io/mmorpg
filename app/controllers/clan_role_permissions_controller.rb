# frozen_string_literal: true

class ClanRolePermissionsController < ApplicationController
  before_action :set_clan

  def update
    authorize @clan, :manage_permissions?

    permission = @clan.clan_role_permissions.find_or_create_by!(
      role: params[:role],
      permission_key: params[:permission_key]
    )
    permission.update!(enabled: cast_boolean(params[:enabled]))

    redirect_to clan_path(@clan), notice: "Permissions updated."
  rescue => e
    redirect_to clan_path(@clan), alert: e.message
  end

  private

  def set_clan
    @clan = Clan.find(params[:clan_id])
  end

  def cast_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
