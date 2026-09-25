# frozen_string_literal: true

# Bilingual equipment encyclopedia (/dress) for Ashen thematic sets.
class DressController < ApplicationController
  def show
    @sets = Game::Equipment::SetBonuses::SET_META.map do |set_id, meta|
      tiers = Game::World::NpcLoadout::CATALOG_TIERS.map do |tier|
        keys = Game::World::NpcLoadout::PIECE_SUFFIXES.map { |suffix| "set-#{set_id}-#{suffix}-t#{tier}" }
        pieces = ItemTemplate.where(key: keys).order(:key).map do |template|
          {
            key: template.key,
            name: template.name,
            slot: template.slot,
            stats: template.stat_modifiers.to_h,
            icon: template.enhancement_rules.to_h["icon"],
            level: template.requirements.to_h["level"]
          }
        end
        {tier:, pieces:}
      end
      {
        id: set_id,
        name_ru: meta[:name_ru],
        name_en: meta[:name_en],
        focus: meta[:focus],
        tiers:
      }
    end
    @selected_set = params[:set].presence || @sets.first&.dig(:id)
    @selected = @sets.find { |row| row[:id] == @selected_set } || @sets.first
  end
end
