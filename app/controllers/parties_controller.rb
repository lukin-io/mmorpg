# frozen_string_literal: true

class PartiesController < ApplicationController
  before_action :set_party, only: [:show, :ready_check, :leave, :promote, :disband]

  def index
    current_user.ensure_social_features!
    @parties = policy_scope(Party).includes(:leader).order(updated_at: :desc)
    @party = Party.new
    @pending_invitations = current_user.party_invitations_received.active.includes(:party, :sender)
  end

  def show
    authorize @party
    @memberships = @party.party_memberships.includes(:user)
    @invitations = @party.party_invitations.active
  end

  def create
    @party = Party.new(party_params.merge(leader: current_user))
    authorize @party

    if @party.save
      redirect_to @party, notice: "Party created."
    else
      @parties = policy_scope(Party).order(updated_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def ready_check
    authorize @party, :manage?
    Parties::ReadyCheck.new(party: @party).start!
    redirect_to @party, notice: "Ready check started."
  end

  def leave
    authorize @party
    membership = @party.party_memberships.find_by!(user: current_user)
    membership.update!(status: :left, left_at: Time.current)
    redirect_to parties_path, notice: "You left the party."
  end

  def promote
    authorize @party, :manage?
    membership = @party.party_memberships.find(params[:membership_id])
    @party.update!(leader: membership.user)
    membership.update!(role: :leader)
    redirect_to @party, notice: "#{membership.user.profile_name} is now the party leader."
  end

  def disband
    authorize @party, :manage?
    @party.destroy
    redirect_to parties_path, notice: "Party disbanded."
  end

  private

  def set_party
    @party = Party.find(params[:id])
  end

  def party_params
    params.require(:party).permit(:name, :purpose, :max_size, activity_metadata: {})
  end
end
