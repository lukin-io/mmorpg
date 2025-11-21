# frozen_string_literal: true

class Clan < ApplicationRecord
  has_many :clan_memberships, dependent: :destroy
  has_many :members, through: :clan_memberships, source: :user
  has_many :clan_territories, dependent: :destroy
  has_many :attacking_wars, class_name: "ClanWar", foreign_key: :attacker_clan_id, dependent: :destroy
  has_many :defending_wars, class_name: "ClanWar", foreign_key: :defender_clan_id, dependent: :destroy

  belongs_to :leader, class_name: "User"

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  before_validation :assign_slug, on: :create

  def treasury_balance(currency)
    case currency
    when :gold then treasury_gold
    when :silver then treasury_silver
    when :premium_tokens then treasury_premium_tokens
    else
      0
    end
  end

  private

  def assign_slug
    return if slug.present?

    self.slug = name.parameterize if name.present?
  end
end
