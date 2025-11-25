# frozen_string_literal: true

class PartyInvitationsController < ApplicationController
  before_action :set_party, only: :create

  def create
    authorize @party, :manage?

    @party_invitation = @party.party_invitations.new(
      party_invitation_params.merge(
        sender: current_user,
        expires_at: 2.hours.from_now
      )
    )

    if @party_invitation.save
      redirect_to @party, notice: "Invitation sent."
    else
      @memberships = @party.party_memberships.includes(:user)
      @invitations = @party.party_invitations.active
      render "parties/show", status: :unprocessable_entity
    end
  end

  def update
    @party_invitation = PartyInvitation.find(params[:id])

    unless @party_invitation.recipient == current_user
      raise Pundit::NotAuthorizedError
    end

    notice =
      case params[:decision]
      when "accept"
        @party_invitation.accept!
        "Invitation accepted."
      when "decline"
        @party_invitation.reject!
        "Invitation declined."
      else
        "No changes made."
      end

    redirect_to parties_path, notice: notice
  end

  private

  def set_party
    @party = Party.find(params[:party_id])
  end

  def party_invitation_params
    params.require(:party_invitation).permit(:recipient_id)
  end
end
