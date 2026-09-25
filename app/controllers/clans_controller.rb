# frozen_string_literal: true

class ClansController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  layout "game"

  TABS = %w[roster manage treasury invites fortresses].freeze

  def show
    @tab = TABS.include?(params[:tab].to_s) ? params[:tab].to_s : default_tab
    @clan = current_character.clan
    @membership = current_character.clan_membership
    @invitations = ClanInvitation.pending.for_character(current_character).includes(:clan, :inviter_character)
    @fortresses = @clan ? WorldFortress.where(owner_clan_id: @clan.id) : WorldFortress.none
    if @clan
      @members = @clan.clan_memberships.includes(:character).order(:role, :joined_at)
      @online_roster = Game::Clans::OnlineRoster.new(clan: @clan).call
      @treasury_items = @clan.clan_treasury_items.includes(:item_template).order(:id)
      @alliance = Game::Clans::Alliance.snapshot_for(@clan)
      @deposit_options = current_character.inventory&.inventory_items
        &.where(equipped: false)
        &.includes(:item_template)
        &.filter_map { |row|
          next if row.item_template.blank?

          [row.item_template.display_name, row.item_template.key, row.quantity]
        } || []
    end
    Game::Onboarding::FirstHour.new(character: current_character).mark!("meet_clan")
  end

  def create
    result = Game::Clans::Create.new(
      character: current_character,
      name: params[:name],
      tag: params[:tag],
      alignment: params[:alignment],
      icon_io: params[:icon],
      require_clan_hall: true
    ).call
    flash_key = result.success ? :notice : :alert
    redirect_to(result.success ? clan_path(tab: "roster") : city_building_path("clan_hall"),
      flash_key => result.message, status: :see_other)
  end

  def invite
    result = Game::Clans::Invite.new(actor: current_character, target_name: params[:target_name]).call
    redirect_clan(result, tab: "manage")
  end

  def respond_invitation
    result = Game::Clans::RespondInvitation.new(
      character: current_character,
      invitation_id: params[:invitation_id],
      accept: ActiveModel::Type::Boolean.new.cast(params[:accept])
    ).call
    redirect_clan(result, tab: result.success && params[:accept].present? ? "roster" : "invites")
  end

  def set_role
    result = Game::Clans::SetRole.new(
      actor: current_character,
      member_character_id: params[:member_character_id],
      role: params[:role]
    ).call
    redirect_clan(result, tab: "manage")
  end

  def membership
    result = Game::Clans::MembershipChange.new(
      actor: current_character,
      action: params[:membership_action],
      target_character_id: params[:member_character_id]
    ).call
    redirect_clan(result, tab: "roster")
  end

  def treasury_lock
    result = Game::Clans::TreasuryLock.new(
      actor: current_character,
      locked: params[:locked]
    ).call
    redirect_clan(result, tab: "treasury")
  end

  def treasury_transfer
    result = Game::Clans::TreasuryTransfer.new(
      actor: current_character,
      action: params[:treasury_action],
      item_key: params[:item_key],
      quantity: params[:quantity],
      amount_nv: params[:amount_nv],
      treasury_item_id: params[:treasury_item_id]
    ).call
    redirect_clan(result, tab: "treasury")
  end

  def upgrade_building
    membership = current_character.clan_membership
    unless membership
      redirect_to clan_path(tab: "fortresses"), alert: t("game.clans.need_clan"), status: :see_other
      return
    end

    fortress = WorldFortress.find_by(id: params[:fortress_id], owner_clan_id: membership.clan_id)
    building = fortress&.fortress_buildings&.find_by(id: params[:building_id])
    unless building
      redirect_to clan_path(tab: "fortresses"), alert: t("game.world.fortress_building_missing"), status: :see_other
      return
    end

    cost = fortress_upgrade_cost(building)
    wallet = current_character.user.currency_wallet
    if wallet.nv_balance.to_d < cost
      redirect_to clan_path(tab: "fortresses"),
        alert: t("game.clans.upgrade_need_nv", amount: cost.to_i),
        status: :see_other
      return
    end

    ActiveRecord::Base.transaction do
      wallet.adjust!(
        amount: -cost,
        reason: "clan.fortress_upgrade",
        metadata: {"building_key" => building.building_key, "fortress_id" => fortress.id}
      )
      building.upgrade!
    end
    redirect_to clan_path(tab: "fortresses"),
      notice: t("game.world.fortress_building_upgraded", name: building.name, level: building.level),
      status: :see_other
  rescue ArgumentError => error
    redirect_to clan_path(tab: "fortresses"), alert: error.message, status: :see_other
  end

  def transfer_leadership
    result = Game::Clans::TransferLeadership.new(
      actor: current_character,
      successor_character_id: params[:member_character_id]
    ).call
    redirect_clan(result, tab: "roster")
  end

  def dissolve
    result = Game::Clans::Dissolve.new(actor: current_character).call
    flash_key = result.success ? :notice : :alert
    redirect_to(result.success ? clan_path(tab: "invites") : clan_path(tab: "manage"),
      flash_key => result.message, status: :see_other)
  end

  def alliance_propose
    result = Game::Clans::Alliance.new(actor: current_character).propose!(target_tag: params[:target_tag])
    redirect_clan(result, tab: "manage")
  end

  def alliance_accept
    result = Game::Clans::Alliance.new(actor: current_character).accept!(from_clan_id: params[:from_clan_id])
    redirect_clan(result, tab: "manage")
  end

  def alliance_break
    result = Game::Clans::Alliance.new(actor: current_character).break!(other_clan_id: params[:other_clan_id])
    redirect_clan(result, tab: "manage")
  end

  private

  def default_tab
    return "invites" if current_character.clan.blank? &&
      ClanInvitation.pending.for_character(current_character).exists?
    return "roster" if current_character.clan.present?

    "invites"
  end

  def redirect_clan(result, tab:)
    flash_key = result.success ? :notice : :alert
    redirect_to clan_path(tab:), flash_key => result.message, status: :see_other
  end

  def fortress_upgrade_cost(building)
    base = building.building_key == "laboratory" ? 150 : 75
    BigDecimal(base + (building.level.to_i * 50))
  end
end
