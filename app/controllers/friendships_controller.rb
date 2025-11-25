# frozen_string_literal: true

class FriendshipsController < ApplicationController
  def index
    current_user.ensure_social_features!
    @friendships = policy_scope(Friendship).includes(:requester, :receiver).order(created_at: :desc)
    @pending_requests = @friendships.select { |friendship| friendship.receiver == current_user && friendship.pending? }
    @outgoing_requests = @friendships.select { |friendship| friendship.requester == current_user && friendship.pending? }
    @accepted_friendships = @friendships.select(&:accepted?)
    @friendship ||= Friendship.new
    @friend_presence = Presence::FriendBroadcaster.new.snapshot_for(current_user)
  end

  def create
    current_user.ensure_social_features!

    @friendship = current_user.friendships.new(friendship_params)
    authorize @friendship

    if resolve_existing_inverse_friendship
      redirect_to friendships_path, notice: "Friend request accepted."
    elsif @friendship.save
      redirect_to friendships_path, notice: "Friend request sent."
    else
      reload_index(with_errors: true)
    end
  end

  def update
    @friendship = authorize Friendship.find(params[:id])

    message =
      case params[:decision]
      when "accept"
        @friendship.accept!
        "Friend added."
      when "reject"
        @friendship.decline!
        "Request rejected."
      else
        "No changes made."
      end

    redirect_to friendships_path, notice: message
  end

  def destroy
    @friendship = authorize Friendship.find(params[:id])
    @friendship.destroy
    redirect_to friendships_path, notice: "Friend removed."
  end

  private

  def friendship_params
    params.require(:friendship).permit(:receiver_id)
  end

  def resolve_existing_inverse_friendship
    inverse = Friendship.find_by(requester_id: friendship_params[:receiver_id], receiver: current_user)
    return false unless inverse&.pending?

    inverse.accept!
    true
  end

  def reload_index(with_errors: false)
    index
    render :index, status: :unprocessable_entity if with_errors
  end
end
