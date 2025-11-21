# frozen_string_literal: true

class ClanWarsController < ApplicationController
  def create
    attacker = current_user.clans.first || (raise Pundit::NotAuthorizedError, "Join a clan first")
    defender = Clan.find(params[:defender_id])
    authorize ClanWar

    scheduler = Clans::WarScheduler.new(attacker:, defender:)
    scheduler.schedule!(territory_key: params[:territory_key], starts_at: Time.zone.parse(params[:scheduled_at]))

    redirect_to clan_path(attacker), notice: "War scheduled."
  rescue StandardError => e
    redirect_to clan_path(attacker), alert: e.message
  end
end

