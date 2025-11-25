# frozen_string_literal: true

class User < ApplicationRecord
  unless const_defined?(:MAX_CHARACTERS)
    MAX_CHARACTERS = 5
  end

  unless const_defined?(:PRIVACY_LEVELS)
    PRIVACY_LEVELS = {
      everyone: 0,
      allies_only: 1,
      nobody: 2
    }.freeze
  end

  rolify

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :confirmable, :trackable, :timeoutable

  has_many :purchases, dependent: :nullify
  has_many :user_sessions, dependent: :destroy
  has_many :premium_token_ledger_entries, dependent: :destroy
  has_many :audit_logs, foreign_key: :actor_id, dependent: :nullify
  has_many :characters, dependent: :destroy
  has_many :chat_channel_memberships, dependent: :destroy
  has_many :chat_channels, through: :chat_channel_memberships
  has_many :chat_messages, foreign_key: :sender_id, dependent: :nullify
  has_many :friendships, foreign_key: :requester_id, dependent: :destroy
  has_many :incoming_friendships, class_name: "Friendship", foreign_key: :receiver_id, dependent: :destroy
  has_many :mail_messages, foreign_key: :sender_id, dependent: :nullify
  has_many :received_mail_messages, class_name: "MailMessage", foreign_key: :recipient_id, dependent: :destroy
  has_many :chat_reports, foreign_key: :reporter_id, dependent: :nullify
  has_many :chat_moderation_actions, foreign_key: :target_user_id, dependent: :destroy
  has_many :moderation_actions_as_actor,
    class_name: "ChatModerationAction",
    foreign_key: :actor_id,
    dependent: :nullify
  has_many :moderation_tickets_reported,
    class_name: "Moderation::Ticket",
    foreign_key: :reporter_id,
    dependent: :nullify
  has_many :moderation_tickets_assigned,
    class_name: "Moderation::Ticket",
    foreign_key: :assigned_moderator_id,
    dependent: :nullify
  has_many :moderation_actions_taken,
    class_name: "Moderation::Action",
    foreign_key: :actor_id,
    dependent: :nullify
  has_many :moderation_actions_received,
    class_name: "Moderation::Action",
    foreign_key: :target_user_id,
    dependent: :destroy
  has_many :moderation_appeals,
    class_name: "Moderation::Appeal",
    foreign_key: :appellant_id,
    dependent: :nullify
  has_many :live_ops_events_requested,
    class_name: "LiveOps::Event",
    foreign_key: :requested_by_id,
    dependent: :nullify
  has_many :guild_memberships, dependent: :destroy
  has_many :guilds, through: :guild_memberships
  has_many :guild_applications, foreign_key: :applicant_id, dependent: :destroy
  has_many :guilds_led, class_name: "Guild", foreign_key: :leader_id, dependent: :nullify
  has_many :guild_bank_entries, foreign_key: :actor_id, dependent: :nullify
  has_many :guild_bulletins, foreign_key: :author_id, dependent: :nullify
  has_many :clan_memberships, dependent: :destroy
  has_many :clans, through: :clan_memberships
  has_many :clans_led, class_name: "Clan", foreign_key: :leader_id, dependent: :nullify
  has_many :clan_applications, foreign_key: :applicant_id, dependent: :destroy
  has_many :reviewed_clan_applications,
    class_name: "ClanApplication",
    foreign_key: :reviewed_by_id,
    dependent: :nullify
  has_many :clan_treasury_transactions, foreign_key: :actor_id, dependent: :nullify
  has_many :clan_message_board_posts, foreign_key: :author_id, dependent: :nullify
  has_many :clan_log_entries, foreign_key: :actor_id, dependent: :nullify
  has_many :clan_moderation_actions, foreign_key: :gm_user_id, dependent: :nullify
  has_one :currency_wallet, dependent: :destroy
  has_many :profession_progresses, dependent: :destroy
  has_many :crafting_jobs, dependent: :nullify
  has_many :achievement_grants, dependent: :destroy
  has_many :housing_plots, dependent: :destroy
  has_many :pet_companions, dependent: :destroy
  has_many :mounts, dependent: :destroy
  has_many :group_listings, foreign_key: :owner_id, dependent: :destroy
  has_many :ignore_list_entries, dependent: :destroy
  has_many :ignored_users, through: :ignore_list_entries, source: :ignored_user
  has_many :ignored_by_entries,
    class_name: "IgnoreListEntry",
    foreign_key: :ignored_user_id,
    dependent: :destroy
  has_many :ignored_by_users, through: :ignored_by_entries, source: :user
  has_many :party_memberships, dependent: :destroy
  has_many :parties, through: :party_memberships
  has_many :parties_led, class_name: "Party", foreign_key: :leader_id, dependent: :destroy
  has_many :party_invitations_sent,
    class_name: "PartyInvitation",
    foreign_key: :sender_id,
    dependent: :nullify
  has_many :party_invitations_received,
    class_name: "PartyInvitation",
    foreign_key: :recipient_id,
    dependent: :destroy
  has_many :arena_participations, dependent: :destroy
  has_many :arena_matches, through: :arena_participations

  after_create :assign_default_role
  after_create :ensure_currency_wallet!
  before_validation :ensure_profile_name

  scope :verified, -> { where.not(confirmed_at: nil) }

  enum :chat_privacy, PRIVACY_LEVELS, prefix: :chat_privacy
  enum :friend_request_privacy, PRIVACY_LEVELS, prefix: :friend_privacy
  enum :duel_privacy, PRIVACY_LEVELS, prefix: :duel_privacy

  validates :profile_name, presence: true, uniqueness: true, length: {maximum: 32}

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

  def suspended?
    suspended_until.present? && suspended_until.future?
  end

  def trade_locked?
    trade_locked_until.present? && trade_locked_until.future?
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

  def allows_chat_from?(other_user)
    return false if ignoring?(other_user) || ignored_by?(other_user)

    privacy_allows?(chat_privacy, other_user)
  end

  def allows_friend_request_from?(other_user)
    privacy_allows?(friend_request_privacy, other_user)
  end

  def allows_duel_from?(other_user)
    privacy_allows?(duel_privacy, other_user)
  end

  def friends_with?(other_user)
    return false if other_user.blank?

    Friendship.accepted_between(self, other_user).exists?
  end

  def friends
    Friendship
      .for_user(self)
      .accepted
      .map { |friendship| (friendship.requester == self) ? friendship.receiver : friendship.requester }
  end

  def ignoring?(other_user)
    return false if other_user.blank?

    ignore_list_entries.exists?(ignored_user: other_user)
  end

  def ignored_by?(other_user)
    return false if other_user.blank?

    ignored_by_entries.exists?(user: other_user)
  end

  def message_rate_limit
    limit = social_settings.fetch("message_rate_limit_per_window", 8).to_i
    return limit if limit.positive?

    8
  end

  def allied_with?(other_user)
    return false if other_user.blank?
    return true if friends_with?(other_user)

    shared_guild_with?(other_user) || shared_clan_with?(other_user)
  end

  def primary_guild
    guild_memberships.active.order(created_at: :desc).first&.guild || guild_memberships.order(created_at: :desc).first&.guild
  end

  def primary_clan
    clan_memberships.order(created_at: :desc).first&.clan
  end

  def sync_character_memberships!
    characters.find_each do |character|
      character.update!(guild: primary_guild, clan: primary_clan)
    end
  end

  def public_profile
    Users::PublicProfile.new(user: self).as_json
  end

  private

  def ensure_profile_name
    return if profile_name.present?

    base = email.to_s.split("@").first.presence || "adventurer"
    candidate = base.parameterize.presence || "adventurer"
    suffix = 1

    while User.where.not(id: id).exists?(profile_name: candidate)
      suffix += 1
      candidate = "#{base.parameterize}-#{suffix}"
    end

    self.profile_name = candidate
  end

  def assign_default_role
    add_role(:player) unless roles.exists?
  end

  def ensure_currency_wallet!
    create_currency_wallet!(gold_balance: 0, silver_balance: 0, premium_tokens_balance: premium_tokens_balance) unless currency_wallet
  end

  def privacy_allows?(setting, other_user)
    return true if other_user == self

    case setting.to_sym
    when :everyone
      true
    when :allies_only
      allied_with?(other_user)
    when :nobody
      false
    else
      true
    end
  end

  def shared_guild_with?(other_user)
    user_guild_ids = guild_memberships.active.pluck(:guild_id)
    other_guild_ids = other_user.guild_memberships.active.pluck(:guild_id)
    (user_guild_ids & other_guild_ids).any?
  end

  def shared_clan_with?(other_user)
    user_clan_ids = clan_memberships.pluck(:clan_id)
    other_clan_ids = other_user.clan_memberships.pluck(:clan_id)
    (user_clan_ids & other_clan_ids).any?
  end
end
