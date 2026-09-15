# frozen_string_literal: true

module ShopHelper
  include InventoriesHelper

  def shop_location_return_label
    @shop_parent_location&.location_short_label || "City"
  end

  def shop_location_return_path
    @shop_parent_location ? world_location_path(@shop_parent_location.location_key) : world_path
  end

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

  def shop_category_icon_style(category)
    index = Game::Shop::Catalog::VALID_CATEGORIES.index(category.to_s) || 18
    "background-position: #{(index % 5) * 25}% #{(index / 5) * 100.0 / 3}%"
  end

  def shop_filter_context
    @catalog.filters
  end

  def shop_item_properties(template, item: nil)
    lines = []
    lines << ["Price", "#{number_with_precision(template.base_price, precision: 2, strip_insignificant_zeros: true, delimiter: ",")} NV"]
    lines << ["Damage", "#{template.stat_modifiers["damage_min"]}-#{template.stat_modifiers["damage_max"]}"] if template.stat_modifiers["damage_min"] && template.stat_modifiers["damage_max"]
    if item ? item.durable? : template.durability_max.to_i.positive?
      current = item ? item.current_durability : template.durability_max
      maximum = item ? item.max_durability : template.durability_max
      lines << ["Durability", "#{current}/#{maximum}"]
    end

    template.stat_modifiers.to_h.each do |stat, value|
      next if value.blank?
      next if %w[damage_min damage_max heal_hp restore_mp family weapon_family reset_allocation].include?(stat.to_s)

      if %w[armor_pierce armor_piercing].include?(stat.to_s)
        lines << [inventory_detail_label(stat), "#{formatted_item_value(value)}%"]
      else
        append_inventory_property_rows(lines, stat, value)
      end
    end

    template.display_properties.each do |label, value|
      append_inventory_property_rows(lines, label, value, signed: false)
    end

    lines << ["Description", template.description] if template.description.present?

    lines.presence || [["Description", "Shop item"]]
  end

  def shop_item_requirements(template)
    rows = [["Mass", template.weight, inventory_can_carry?(template.weight)]]
    template.requirements.to_h.sort_by.with_index { |(key, _value), index| [shop_requirement_order(key), index] }.each do |key, value|
      current = shop_requirement_current_value(key)
      met = current.nil? || current.to_i >= value.to_i
      label = inventory_detail_label(key)
      rows << [label, value, met]
    end
    rows
  end

  def shop_sale_price(item)
    Game::Shop::Catalog.sale_price_for_item(item,
      trading_skill: Game::Shop::LicenseRules.trading_skill(current_character))
  end

  def shop_buy_block_reason(template)
    return "Unavailable" unless template.available_in_shop?
    license_reason = @shop_license_rules.purchase_block_reason(template)
    return license_reason if license_reason
    stock = @shop_stocks&.[](template.id)
    return "Unavailable" unless stock
    return "Out of stock" if stock.out_of_stock?
    return "Not enough NV." if @wallet.nv_balance.to_d < template.base_price.to_d
    return if Game::Shop::LicenseRules.definition(template)
    return "Carrying capacity exceeded." unless inventory_can_carry?(template.weight)
    return "no room" unless inventory_has_slot_for?(template)

    nil
  end

  def shop_sell_block_reason(item)
    return "Invalid durability" unless item.valid_sale_durability?
    return "equipped or protected" unless item.tradable?
    return "not accepted" unless shop_sale_price(item).positive?

    return "A trading license is required to sell items to the shop." unless @shop_license_rules.active?(:trading)

    stock = @shop_stocks&.[](item.item_template_id)
    return "This shop does not accept this item." unless stock
    return "The shop has enough of this item." unless stock.accepts_return?
    return "The shop does not have enough NV." unless @shop_account && @shop_account.nv_balance >= shop_sale_price(item)

    nil
  end

  def shop_stock_label(template)
    stock = @shop_stocks&.[](template.id)
    return "—" unless stock
    return stock.current.to_s if stock.maximum.nil?

    "#{stock.current} / #{stock.maximum}"
  end

  def shop_max_weight
    @shop_max_weight ||= @inventory.max_weight
  end

  private

  def shop_requirement_order(key)
    normalized = normalize_item_detail_key(key)
    return 0 if normalized == "level"
    return 1 if Character.normalize_stat_key(normalized)
    return 2 if %w[ap action_points].include?(normalized)

    3
  end

  def inventory_can_carry?(weight)
    @inventory.current_weight.to_i + weight.to_i <= shop_max_weight.to_i
  end

  def inventory_has_slot_for?(template)
    partial_stack = @shop_inventory_items.any? do |item|
      next false unless item.item_template_id == template.id && !item.equipped?

      item.quantity.to_i < template.stack_limit.to_i
    end
    partial_stack || @shop_inventory_items.size < @inventory.slot_capacity.to_i
  end

  def shop_requirement_current_value(key)
    normalized = key.to_s.strip.downcase.tr(" -", "_")
    normalized = "ap" if normalized == "action_points"
    @shop_requirement_values ||= {}
    @shop_requirement_values.fetch(normalized) do
      @shop_requirement_values[normalized] = load_shop_requirement_value(normalized)
    end
  end

  def load_shop_requirement_value(normalized)
    return current_character.level.to_i if normalized == "level"
    return current_character.max_action_points.to_i if %w[ap action_points].include?(normalized)

    stat_key = Character.normalize_stat_key(normalized)
    return (@shop_character_stats ||= current_character.stats).get(stat_key).to_i if stat_key

    skill_key = {
      "knife_skill" => :knife_mastery,
      "staff_skill" => :staff_mastery,
      "two_handed_skill" => :two_handed_mastery,
      "dual_wield_skill" => :dual_wielding,
      "sword_skill" => :sword_mastery,
      "axe_skill" => :axe_mastery
    }.fetch(normalized, normalized.to_sym)
    if defined?(Game::Skills::PassiveSkillRegistry) && Game::Skills::PassiveSkillRegistry.valid?(skill_key)
      @shop_skill_values ||= {}
      return @shop_skill_values[skill_key] ||= current_character.passive_skill_level(skill_key).to_i
    end

    nil
  end
end
