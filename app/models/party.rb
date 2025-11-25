# frozen_string_literal: true

class Party < ApplicationRecord
  STATUSES = {
    forming: 0,
    queued: 1,
    in_instance: 2,
    completed: 3,
    disbanded: 4
  }.freeze

  READY_STATES = {
    idle: 0,
    running: 1,
    resolved: 2
  }.freeze

  enum :status, STATUSES
  enum :ready_check_state, READY_STATES

  belongs_to :leader, class_name: "User"
  belongs_to :chat_channel, optional: true

  has_many :party_memberships, dependent: :destroy
  has_many :members, through: :party_memberships, source: :user
  has_many :party_invitations, dependent: :destroy

  validates :name, presence: true, length: {maximum: 80}
  validates :max_size, numericality: {greater_than: 1, less_than_or_equal_to: 10}

  after_create :bootstrap_membership!
  after_create :ensure_chat_channel!

  def ready_check_running?
    ready_check_state == "running"
  end

  def active_members
    party_memberships.active.includes(:user)
  end

  private

  def bootstrap_membership!
    party_memberships.create!(
      user: leader,
      role: :leader,
      status: :active,
      ready_state: :ready,
      joined_at: Time.current
    )
  end

  def ensure_chat_channel!
    return if chat_channel.present?

    channel = ChatChannel.create!(
      name: "#{name} Party Chat",
      channel_type: :party,
      system_owned: true,
      metadata: {"party_id" => id}
    )
    update!(chat_channel: channel)
    channel.ensure_membership!(leader)
  end
end
