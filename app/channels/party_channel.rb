# frozen_string_literal: true

# ActionCable channel for real-time party updates.
#
# Broadcasts member changes, ready checks, and party status.
#
# @example Subscribe to a party
#   consumer.subscriptions.create({ channel: "PartyChannel", party_id: 1 })
#
class PartyChannel < ApplicationCable::Channel
  def subscribed
    @party = Party.find_by(id: params[:party_id])
    reject unless @party && can_view_party?

    stream_from "party:#{@party.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def can_view_party?
    return true if @party.party_memberships.exists?(user: current_user)
    return true if @party.party_invitations.exists?(user: current_user)

    false
  end
end
