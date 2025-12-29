# frozen_string_literal: true

class PartyMembershipsController < ApplicationController
  before_action :set_party

  def update
    membership = @party.party_memberships.find(params[:id])
    authorize membership.party, :show?

    unless membership.user == current_user || membership.party.leader == current_user
      raise Pundit::NotAuthorizedError
    end

    ready_state = params[:ready_state].presence_in(%w[ready not_ready]) || "ready"
    Parties::ReadyCheck.new(party: @party).mark_ready!(membership, ready_state:)

    redirect_to @party, notice: "Ready state updated."
  end

  def destroy
    authorize @party, :manage?
    membership = @party.party_memberships.find(params[:id])
    membership.update!(status: :left, left_at: Time.current)

    redirect_to @party, notice: "#{membership.user.profile_name} removed from party."
  end

  private

  def set_party
    @party = Party.find(params[:party_id])
  end
end
