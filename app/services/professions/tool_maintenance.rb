# frozen_string_literal: true

module Professions
  # Handles degrading and repairing profession tools.
  #
  # Usage:
  #   Professions::ToolMaintenance.new(tool:, inventory:).repair!(materials: {"Iron Ingot" => 2})
  class ToolMaintenance
    def initialize(tool:, inventory:)
      @tool = tool
      @inventory = inventory
    end

    def repair!(materials:)
      inventory.consume_materials!(materials) if materials.present?
      tool.repair!(amount: tool.max_durability)
      tool
    end

    def self.degrade!(tool:, amount:)
      tool&.degrade!(amount)
    end

    private

    attr_reader :tool, :inventory
  end
end
