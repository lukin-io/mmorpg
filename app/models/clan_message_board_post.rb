# frozen_string_literal: true

# ClanMessageBoardPost powers the internal bulletin board plus optional
# Discord broadcasts for announcements. Posts are rendered on the clan show
# page and mirrored externally via Clans::DiscordWebhookPublisher when opted in.
#
# Usage:
#   clan.clan_message_board_posts.create!(author: user, title: "Siege Night", body: "...", published_at: Time.current)
class ClanMessageBoardPost < ApplicationRecord
  belongs_to :clan
  belongs_to :author, class_name: "User"

  validates :title, :body, :published_at, presence: true

  scope :recent, -> { order(pinned: :desc, published_at: :desc) }

  def broadcastable?
    clan.discord_webhook_url.present? && broadcasted_at.blank?
  end
end
