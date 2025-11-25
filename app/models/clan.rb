# frozen_string_literal: true

class Clan < ApplicationRecord
  has_many :clan_memberships, dependent: :destroy
  has_many :members, through: :clan_memberships, source: :user
  has_many :clan_territories, dependent: :destroy
  has_many :attacking_wars, class_name: "ClanWar", foreign_key: :attacker_clan_id, dependent: :destroy
  has_many :defending_wars, class_name: "ClanWar", foreign_key: :defender_clan_id, dependent: :destroy
  has_many :clan_role_permissions, dependent: :destroy
  has_many :clan_xp_events, dependent: :destroy
  has_many :clan_treasury_transactions, dependent: :destroy
  has_many :clan_stronghold_upgrades, dependent: :destroy
  has_many :clan_research_projects, dependent: :destroy
  has_many :clan_applications, dependent: :destroy
  has_many :clan_quests, dependent: :destroy
  has_many :clan_message_board_posts, dependent: :destroy
  has_many :clan_log_entries, dependent: :destroy
  has_many :clan_moderation_actions, dependent: :destroy

  belongs_to :leader, class_name: "User"

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :level, numericality: {greater_than: 0}
  validates :experience, numericality: {greater_than_or_equal_to: 0}

  before_validation :assign_slug, on: :create
  after_create :seed_recruitment_settings!
  after_create :seed_treasury_rules!
  after_create :seed_permission_matrix!

  def treasury_balance(currency)
    case currency.to_sym
    when :gold then treasury_gold
    when :silver then treasury_silver
    when :premium_tokens then treasury_premium_tokens
    else
      0
    end
  end

  def update_treasury!(currency, delta)
    attribute = case currency.to_sym
    when :gold then :treasury_gold
    when :silver then :treasury_silver
    when :premium_tokens then :treasury_premium_tokens
    else
      raise ArgumentError, "Unknown currency #{currency}"
    end

    increment!(attribute, delta)
  end

  def recruitment_questions
    stored = Array(recruitment_settings.fetch("questions", []))
    return stored if stored.any?

    defaults = Array(clan_config.dig("recruitment", "default_vetting_questions"))
    update!(recruitment_settings: recruitment_settings.merge("questions" => defaults)) if defaults.any?
    defaults
  end

  def withdrawal_limit_for(role, currency)
    limits = treasury_rules.fetch(role.to_s, {})
    limits.fetch(currency.to_s, 0)
  end

  def fast_travel_node_ids
    Array(fast_travel_nodes)
  end

  def clan_config
    Rails.configuration.x.clans
  end

  private

  def assign_slug
    return if slug.present?

    self.slug = name.parameterize if name.present?
  end

  def seed_recruitment_settings!
    return if recruitment_settings.present?

    defaults = {
      "questions" => Array(clan_config.dig("recruitment", "default_vetting_questions")),
      "auto_accept" => clan_config.dig("recruitment", "auto_accept") || {}
    }
    update_column(:recruitment_settings, defaults) if defaults.values.any?(&:present?)
  end

  def seed_treasury_rules!
    return if treasury_rules.present?

    rules = clan_config.dig("treasury", "withdrawal_limits") || {}
    update_column(:treasury_rules, rules)
  end

  def seed_permission_matrix!
    Clans::PermissionMatrix.seed_defaults!(clan: self)
  end
end
