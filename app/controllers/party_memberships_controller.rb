# frozen_string_literal: true

class PartyMembershipsController < ApplicationController
  before_action :set_party

  def update
    membership = @party.party_memberships.find(params[:id])
    authorize membership.party, :show?

    unless membership.user == current_user || membership.party.leader == current_user
      raise Pundit::NotAuthorizedError
    end

    ready = params[:ready_state].present? ? ActiveModel::Type::Boolean.new.cast(params[:ready_state]) : true
    Parties::ReadyCheck.new(party: @party).mark_ready!(membership, ready:)

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
