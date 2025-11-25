# frozen_string_literal: true

class Guild < ApplicationRecord
  include ActionView::RecordIdentifier

  has_many :guild_memberships, dependent: :destroy
  has_many :members, through: :guild_memberships, source: :user
  has_many :guild_applications, dependent: :destroy
  has_many :guild_bank_entries, dependent: :destroy
  has_many :guild_missions, dependent: :destroy
  has_many :guild_ranks, dependent: :destroy
  has_many :guild_bulletins, dependent: :destroy
  has_many :guild_perks, dependent: :destroy

  belongs_to :leader, class_name: "User"

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  before_validation :assign_slug, on: :create

  scope :recruiting, -> { where("recruitment_settings ->> 'status' = ?", "open") }

  after_create :ensure_default_ranks!

  def treasury_balance(currency)
    case currency
    when :gold then treasury_gold
    when :silver then treasury_silver
    when :premium_tokens then treasury_premium_tokens
    else
      0
    end
  end

  def update_treasury!(currency, delta)
    attribute = case currency
    when :gold then :treasury_gold
    when :silver then :treasury_silver
    when :premium_tokens then :treasury_premium_tokens
    else
      raise ArgumentError, "Unknown currency #{currency}"
    end

    increment!(attribute, delta)
  end

  def dom_id_suffix
    dom_id(self, :panel)
  end

  def default_rank
    guild_ranks.ordered.first
  end

  def ensure_default_ranks!
    return if guild_ranks.exists?

    GuildRank.transaction do
      [
        {name: "Leader", position: 0, permissions: {invite: true, kick: true, manage_bank: true, post_bulletins: true, start_war: true}},
        {name: "Officer", position: 1, permissions: {invite: true, kick: true, manage_bank: true, post_bulletins: true}},
        {name: "Member", position: 2, permissions: {invite: false, kick: false, manage_bank: false, post_bulletins: false}}
      ].each do |rank_attrs|
        guild_ranks.create!(rank_attrs)
      end
    end
  end

  private

  def assign_slug
    return if slug.present?

    self.slug = name.parameterize if name.present?
  end
end
