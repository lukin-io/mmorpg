# frozen_string_literal: true

module Arena
  # Admission rule shared by application creation, side joining and start-time
  # revalidation. Reads authored artifact grades; never guesses from item names,
  # prices or rarity. Restricted fights do not silently remove player equipment.
  class EquipmentRule
    def initialize(kind)
      @kind = kind.to_s
    end

    def rejection_reason(character)
      items = character.inventory&.inventory_items&.equipped&.includes(:item_template)&.to_a || []
      return "Remove all equipment for an unarmed fight" if @kind == "no_weapons" && items.any?
      return unless @kind.in?(%w[no_artifacts limited_artifacts])

      grades = [character.metadata.to_h.fetch("artifact_grade", "none")]
      grades.concat(items.map { |item| item.effect_modifiers.fetch("artifact_grade", "none") })
      config = Game::Combat::Calibration.config
      allowed = if @kind == "no_artifacts"
        ["none"]
      else
        config.fetch("artifact_multipliers").select { |_, multiplier| multiplier <= config.fetch("arena_rules").fetch("limited_artifact_max_multiplier") }.keys
      end
      "Equipment exceeds this fight's artifact limit" unless grades.all? { |grade| allowed.include?(grade) }
    end
  end
end
