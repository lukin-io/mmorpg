# frozen_string_literal: true

module ShopHelper
  def shop_mode_options
    Game::Shop::Catalog::MODES
  end

  def shop_category_options
    Game::Shop::Catalog::CATEGORIES
  end

  def shop_mode_label(mode)
    shop_mode_options.to_h.fetch(mode, mode.to_s)
  end

  def shop_category_label(category)
    shop_category_options.to_h.fetch(category, category.to_s)
  end

  def shop_item_properties(template)
    lines = []
    lines << ["Тип", template.item_type.to_s.titleize]
    lines << ["Слот", EquipmentSlots::LABELS[template.slot] || template.slot] if template.equippable?
    lines << ["Цена", "#{number_with_delimiter(template.base_price)} NV"]
    lines << ["Прочность", template.durability_max] if template.durability_max.to_i.positive?

    template.stat_modifiers.to_h.each do |stat, value|
      next if value.blank?

      lines << [stat.to_s.titleize, signed_shop_value(value)]
    end

    lines.presence || [["Описание", "Предмет лавки"]]
  end

  def shop_item_requirements(template)
    rows = [["Масса", template.weight, inventory_can_carry?(template.weight)]]
    template.requirements.to_h.each do |key, value|
      current = shop_requirement_current_value(key)
      met = current.nil? || current.to_i >= value.to_i
      label = key.to_s.titleize
      display = current.nil? ? value : "#{value} (сейчас #{current})"
      rows << [label, display, met]
    end
    rows
  end

  def shop_sale_price(item)
    Game::Shop::Catalog.sale_price(item.item_template)
  end

  def shop_buy_block_reason(template)
    return "нет цены" unless template.base_price.to_i.positive?
    return "не хватает NV" if @wallet.nv_balance.to_i < template.base_price.to_i
    return "перегруз" unless inventory_can_carry?(template.weight)
    return "нет места" unless inventory_has_slot_for?(template)

    nil
  end

  def shop_sell_block_reason(item)
    return "надето или защищено" if item.protected_from_discard?
    return "не принимается" unless shop_sale_price(item).positive?

    nil
  end

  def shop_stock_label(_template)
    "в наличии"
  end

  def shop_item_icon(template)
    case Game::Shop::Catalog.category_for(template)
    when "weapons" then "WP"
    when "armor" then "AR"
    when "jewelry" then "AC"
    when "consumables" then "EL"
    when "materials" then "RS"
    else "IT"
    end
  end

  private

  def signed_shop_value(value)
    numeric = value.to_i
    return value unless numeric.to_s == value.to_s

    numeric.positive? ? "+#{numeric}" : numeric.to_s
  end

  def inventory_can_carry?(weight)
    @inventory.current_weight.to_i + weight.to_i <= @inventory.weight_capacity.to_i
  end

  def inventory_has_slot_for?(template)
    partial_stack = @inventory.inventory_items.where(item_template: template, equipped: false).any? do |item|
      item.quantity.to_i < template.stack_limit.to_i
    end
    partial_stack || @inventory.inventory_items.count < @inventory.slot_capacity.to_i
  end

  def shop_requirement_current_value(key)
    normalized = key.to_s.strip.downcase.tr(" -", "_")
    return current_character.level.to_i if normalized == "level"
    return current_character.max_action_points.to_i if %w[ap action_points].include?(normalized)

    stat_key = Character.normalize_stat_key(normalized)
    return current_character.stats.get(stat_key).to_i if stat_key

    skill_key = normalized.to_sym
    if defined?(Game::Skills::PassiveSkillRegistry) && Game::Skills::PassiveSkillRegistry.valid?(skill_key)
      return current_character.passive_skill_level(skill_key).to_i
    end

    nil
  end
end
