# frozen_string_literal: true

class ClanWarsController < ApplicationController
  def create
    attacker = Clan.find(params[:clan_id])
    authorize attacker, :declare_war?
    defender = Clan.find(params[:defender_id])

    starts_at = Time.zone.parse(params[:scheduled_at])
    scheduler = Clans::WarScheduler.new(attacker:, defender:)
    support_param = params[:support_objectives]
    support_objectives = if support_param.is_a?(String)
      support_param.split(",").map(&:strip)
    else
      Array(support_param)
    end.reject(&:blank?)
    scheduler.schedule!(
      territory_key: params[:territory_key],
      starts_at: starts_at,
      support_objectives: support_objectives
    )

    redirect_to clan_path(attacker), notice: "War scheduled."
  rescue => e
    redirect_to clan_path(attacker), alert: e.message
  end
end
