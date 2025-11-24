# frozen_string_literal: true

# Inventory encapsulates slot + weight capacity per character.
class Inventory < ApplicationRecord
  belongs_to :character
  has_many :inventory_items, dependent: :destroy

  validates :slot_capacity, :weight_capacity, numericality: {greater_than: 0}
  validates :current_weight, numericality: {greater_than_or_equal_to: 0}

  def material_count(item_name)
    inventory_items
      .joins(:item_template)
      .where(item_templates: {name: item_name})
      .sum(:quantity)
  end

  def materials_available?(materials)
    materials.all? do |item_name, quantity|
      material_count(item_name) >= quantity.to_i
    end
  end

  def consume_materials!(materials)
    ApplicationRecord.transaction do
      materials.each do |item_name, quantity|
        remove_quantity!(item_name, quantity.to_i)
      end
    end
  end

  def add_item_by_name!(item_name, quantity:)
    template = ItemTemplate.find_by!(name: item_name)
    item = inventory_items.find_or_initialize_by(item_template: template)
    item.quantity = (item.quantity || 0) + quantity
    item.weight = template.weight
    item.save!
  end

  private

  def remove_quantity!(item_name, quantity)
    remaining = quantity
    inventory_items
      .joins(:item_template)
      .where(item_templates: {name: item_name})
      .order(:id)
      .each do |item|
        break if remaining <= 0

        if item.quantity > remaining
          item.decrement!(:quantity, remaining)
          remaining = 0
        else
          remaining -= item.quantity
          item.destroy!
        end
      end

    raise ActiveRecord::RecordInvalid, "Missing #{item_name}" if remaining.positive?
  end
end
