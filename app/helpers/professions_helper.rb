# frozen_string_literal: true

module ProfessionsHelper
  # Human craft input line: "Пепельный бинт 1/2" using inventory counts.
  def craft_input_labels(recipe, character:)
    Game::Professions::Templates.ensure_craft_items!
    inventory = character.inventory
    recipe.fetch("inputs").map do |item_key, need|
      template = ItemTemplate.find_by(key: item_key.to_s)
      name = template&.display_name || item_key.to_s
      have = inventory_qty(inventory, template)
      "#{name} #{have}/#{need}"
    end.join(", ")
  end

  # Returns {ready:, reason:, code:} for workshop/hospital craft buttons.
  def craft_readiness(recipe, character:, skill:)
    Game::Professions::Templates.ensure_craft_items!
    min_skill = recipe.fetch("min_skill", 0).to_i
    if skill.to_i < min_skill
      return {
        ready: false,
        code: :need_skill,
        reason: I18n.t("game.professions.need_skill", amount: min_skill, current: skill.to_i)
      }
    end

    inventory = character.inventory
    missing = recipe.fetch("inputs").filter_map do |item_key, need|
      template = ItemTemplate.find_by(key: item_key.to_s)
      have = inventory_qty(inventory, template)
      next if have >= need.to_i

      template&.display_name || item_key.to_s
    end
    if missing.any?
      return {
        ready: false,
        code: :need_mats,
        reason: I18n.t("game.professions.need_mats", list: missing.join(", "))
      }
    end

    {ready: true, code: nil, reason: nil}
  end

  def craft_block_recovery_link(gate)
    case gate[:code]
    when :need_mats
      link_to t("game.professions.gather_world"), world_path, class: "nl-sheet-link", data: {craft_recovery: "world"}
    when :need_skill
      link_to t("game.professions.open_inventory"), inventory_path, class: "nl-sheet-link", data: {craft_recovery: "inventory"}
    end
  end

  private

  def inventory_qty(inventory, template)
    return 0 unless inventory && template

    inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
  end
end
