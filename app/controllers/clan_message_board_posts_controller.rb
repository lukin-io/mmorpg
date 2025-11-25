# frozen_string_literal: true

class ClanMessageBoardPostsController < ApplicationController
  before_action :set_clan

  def create
    authorize @clan, :post_announcements?

    post = @clan.clan_message_board_posts.new(post_params)
    post.author = current_user
    post.published_at ||= Time.current

    if post.save
      Clans::DiscordWebhookPublisher.new(clan: @clan, post: post).broadcast! if broadcast_param?
      redirect_to clan_path(@clan), notice: "Announcement published."
    else
      redirect_to clan_path(@clan), alert: post.errors.full_messages.to_sentence
    end
  end

  def update
    authorize @clan, :post_announcements?
    post = @clan.clan_message_board_posts.find(params[:id])
    if post.update(post_params)
      redirect_to clan_path(@clan), notice: "Announcement updated."
    else
      redirect_to clan_path(@clan), alert: post.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize @clan, :post_announcements?
    post = @clan.clan_message_board_posts.find(params[:id])
    post.destroy
    redirect_to clan_path(@clan), notice: "Announcement removed."
  end

  private

  def set_clan
    @clan = Clan.find(params[:clan_id])
  end

  def post_params
    params.require(:clan_message_board_post).permit(:title, :body, :pinned, :published_at)
  end

  def broadcast_param?
    ActiveModel::Type::Boolean.new.cast(params[:broadcast])
  end
end
