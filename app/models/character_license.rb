# frozen_string_literal: true

# A purchased permission displayed under Character Abilities. The granted kind,
# tier, name and interval are snapshots; later catalog edits cannot extend or
# rewrite a player's purchased permission.
class CharacterLicense < ApplicationRecord
  belongs_to :character
  belongs_to :item_template
  belongs_to :world_action_offer

  validates :kind, inclusion: {in: %w[trading doctor]}
  validates :tier, numericality: {only_integer: true, in: 1..3}
  validates :name, :starts_at, :expires_at, presence: true
  validates :world_action_offer_id, uniqueness: true
  validate :positive_interval
  validate :owned_purchase_offer

  scope :active_at, ->(at) { where("starts_at <= ? AND expires_at > ?", at, at) }

  def active?(at: Time.current)
    starts_at.present? && expires_at.present? && starts_at <= at && at < expires_at
  end

  private

  def positive_interval
    return if starts_at.blank? || expires_at.blank? || expires_at > starts_at

    errors.add(:expires_at, "must be after activation")
  end

  def owned_purchase_offer
    return unless world_action_offer
    return if world_action_offer.character_id == character_id && world_action_offer.action_type == "shop_buy" &&
      world_action_offer.target_type == "ItemTemplate" && world_action_offer.target_id == item_template_id

    errors.add(:world_action_offer, "must be this character's license purchase")
  end
end
