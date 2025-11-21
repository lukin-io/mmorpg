# frozen_string_literal: true

class User < ApplicationRecord
  rolify

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :confirmable, :trackable, :timeoutable

  has_many :purchases, dependent: :nullify
  has_many :user_sessions, dependent: :destroy
  has_many :premium_token_ledger_entries, dependent: :destroy
  has_many :audit_logs, foreign_key: :actor_id, dependent: :nullify

  after_create :assign_default_role

  scope :verified, -> { where.not(confirmed_at: nil) }

  def verified_for_social_features?
    confirmed?
  end

  def ensure_social_features!
    return if verified_for_social_features?

    raise Pundit::NotAuthorizedError, "Email verification required"
  end

  def moderator?
    has_any_role?(:moderator, :gm, :admin)
  end

  def timeout_in
    30.minutes
  end

  def active_session_for(device_id)
    user_sessions.find_by(device_id: device_id)
  end

  def mark_last_seen!(timestamp: Time.current)
    update_columns(last_seen_at: timestamp)
  end

  private

  def assign_default_role
    add_role(:player) unless roles.exists?
  end
end
