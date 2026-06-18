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
    lines << ["Type", template.item_type.to_s.titleize]
    lines << ["Slot", EquipmentSlots::LABELS[template.slot] || template.slot] if template.equippable?
    lines << ["Price", "#{number_with_delimiter(template.base_price)} NV"]
    lines << ["Durability", template.durability_max] if template.durability_max.to_i.positive?
    lines << ["Damage", "#{template.stat_modifiers["damage_min"]}-#{template.stat_modifiers["damage_max"]}"] if template.stat_modifiers["damage_min"] && template.stat_modifiers["damage_max"]

    template.stat_modifiers.to_h.each do |stat, value|
      next if value.blank?
      next if %w[damage_min damage_max heal_hp restore_mp family weapon_family reset_allocation].include?(stat.to_s)

      lines << [stat.to_s.titleize, signed_shop_value(value)]
    end

    template.display_properties.each do |label, value|
      lines << [label.to_s.titleize, value]
    end

    lines << ["Description", template.description] if template.description.present?

    lines.presence || [["Description", "Shop item"]]
  end

  def shop_item_requirements(template)
    rows = [["Mass", template.weight, inventory_can_carry?(template.weight)]]
    template.requirements.to_h.each do |key, value|
      current = shop_requirement_current_value(key)
      met = current.nil? || current.to_i >= value.to_i
      label = key.to_s.titleize
      display = current.nil? ? value : "#{value} (current #{current})"
      rows << [label, display, met]
    end
    rows
  end

  def shop_sale_price(item)
    Game::Shop::Catalog.sale_price_for_item(item)
  end

  def shop_buy_block_reason(template)
    return "no price" unless template.base_price.to_i.positive?
    return "Нет в наличии" if template.out_of_stock?
    return "Недостаточно средств или превышена допустимая масса" if @wallet.nv_balance.to_d < template.base_price.to_d
    return "Недостаточно средств или превышена допустимая масса" unless inventory_can_carry?(template.weight)
    return "no room" unless inventory_has_slot_for?(template)

    nil
  end

  def shop_sell_block_reason(item)
    return "equipped or protected" if item.protected_from_discard?
    return "not accepted" unless shop_sale_price(item).positive?

    nil
  end

  def shop_stock_label(template)
    return "#{template.shop_stock_current}/#{template.shop_stock_max}" if template.shop_stock_limited?

    "in stock"
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
    return value.to_json if value.is_a?(Hash) || value.is_a?(Array)

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

    skill_key = {
      "knife_skill" => :knife_mastery,
      "staff_skill" => :staff_mastery,
      "two_handed_skill" => :two_handed_mastery,
      "sword_skill" => :sword_mastery,
      "axe_skill" => :axe_mastery
    }.fetch(normalized, normalized.to_sym)
    if defined?(Game::Skills::PassiveSkillRegistry) && Game::Skills::PassiveSkillRegistry.valid?(skill_key)
      return current_character.passive_skill_level(skill_key).to_i
    end

    nil
  end
end
