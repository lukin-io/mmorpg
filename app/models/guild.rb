# frozen_string_literal: true

class Guild < ApplicationRecord
  include ActionView::RecordIdentifier

  has_many :guild_memberships, dependent: :destroy
  has_many :members, through: :guild_memberships, source: :user
  has_many :guild_applications, dependent: :destroy
  has_many :guild_bank_entries, dependent: :destroy

  belongs_to :leader, class_name: "User"

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  before_validation :assign_slug, on: :create

  scope :recruiting, -> { where("recruitment_settings ->> 'status' = ?", "open") }

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

  private

  def assign_slug
    return if slug.present?

    self.slug = name.parameterize if name.present?
  end
end
