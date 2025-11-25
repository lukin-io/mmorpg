# frozen_string_literal: true

class ChatChannel < ApplicationRecord
  include ActionView::RecordIdentifier

  CHANNEL_TYPES = {
    global: 0,
    local: 1,
    guild: 2,
    clan: 3,
    party: 4,
    whisper: 5,
    system: 6,
    arena: 7
  }.freeze

  enum :channel_type, CHANNEL_TYPES

  belongs_to :creator, class_name: "User", optional: true

  has_many :memberships,
    class_name: "ChatChannelMembership",
    dependent: :destroy
  has_many :users, through: :memberships
  has_many :chat_messages, dependent: :destroy

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  scope :system_owned, -> { where(system_owned: true) }
  scope :public_channels, -> { where(channel_type: [channel_types[:global], channel_types[:local]]) }

  before_validation :assign_slug, on: :create

  def membership_required?
    !(global? || local? || arena?)
  end

  def ensure_membership!(user)
    return unless membership_required?
    return if memberships.exists?(user:)

    memberships.create!(user:)
  end

  def stream_dom_id
    dom_id(self, :messages)
  end

  private

  def assign_slug
    return if slug.present?

    base = channel_type.presence || "channel"
    self.slug = "#{base}-#{SecureRandom.hex(4)}"
  end
end
