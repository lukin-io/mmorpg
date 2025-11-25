# frozen_string_literal: true

class ClansController < ApplicationController
  before_action :ensure_active_character!, only: [:new, :create]
  before_action :set_clan, only: [:show, :edit, :update]

  helper_method :clan_membership, :clan_permission_matrix

  def index
    @clans = policy_scope(Clan)
      .includes(:leader)
      .order(level: :desc, prestige: :desc)
  end

  def show
    authorize @clan
    @territories = @clan.clan_territories
    @wars = ClanWar.where(attacker_clan: @clan).or(ClanWar.where(defender_clan: @clan))
    @message_board_posts = @clan.clan_message_board_posts.recent.limit(15)
    @stronghold_upgrades = @clan.clan_stronghold_upgrades.order(created_at: :desc)
    @research_projects = @clan.clan_research_projects.order(created_at: :desc)
    @active_clan_quests = @clan.clan_quests.includes(:quest).where(status: :active)
    @pending_applications = clan_permission_matrix.allows?(:manage_recruitment) ? @clan.clan_applications.awaiting_review.includes(:applicant, :character) : []
    @treasury_transactions = clan_permission_matrix.allows?(:manage_treasury) ? @clan.clan_treasury_transactions.order(created_at: :desc).limit(10) : []
    @recent_logs = clan_permission_matrix.allows?(:manage_permissions) ? @clan.clan_log_entries.recent.limit(20) : []
    @next_level_xp = Clans::XpProgression.new(clan: @clan).threshold_for(@clan.level + 1)
  end

  def new
    @clan = authorize Clan.new
    @founding_requirements = Rails.configuration.x.clans["founding"]
  end

  def create
    @clan = authorize Clan.new(clan_params.merge(leader: current_user))

    Clans::FoundingGate.new(
      user: current_user,
      character: current_character,
      wallet: current_user.currency_wallet
    ).enforce!(clan_name: @clan.name)

    if @clan.save
      membership = @clan.clan_memberships.create!(user: current_user, role: :leader, joined_at: Time.current)
      Clans::LogWriter.new(clan: @clan).record!(action: "clan.founded", actor: current_user, metadata: {membership_id: membership.id})
      redirect_to @clan, notice: "Clan founded successfully."
    else
      @founding_requirements = Rails.configuration.x.clans["founding"]
      render :new, status: :unprocessable_entity
    end
  rescue Clans::FoundingGate::RequirementError => e
    @clan.errors.add(:base, e.message)
    @founding_requirements = Rails.configuration.x.clans["founding"]
    render :new, status: :unprocessable_entity
  end

  def update
    authorize @clan, :manage_permissions?
    if @clan.update(clan_params)
      redirect_to @clan, notice: "Clan settings updated."
    else
      @territories = @clan.clan_territories
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_clan
    @clan = Clan.find(params[:id])
  end

  def clan_membership
    return @clan_membership if defined?(@clan_membership)

    @clan_membership = @clan&.clan_memberships&.find_by(user: current_user)
  end

  def clan_permission_matrix
    @clan_permission_matrix ||= Clans::PermissionMatrix.new(clan: @clan, membership: clan_membership)
  end

  def clan_params
    params.require(:clan).permit(
      :name,
      :description,
      :discord_webhook_url,
      banner_data: {},
      recruitment_settings: {},
      treasury_rules: {},
      infrastructure_state: {}
    )
  end
end
