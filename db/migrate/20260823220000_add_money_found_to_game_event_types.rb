# frozen_string_literal: true

class AddMoneyFoundToGameEventTypes < ActiveRecord::Migration[8.1]
  CURRENT_TYPES = %w[fight_finished item_found money_found system_information world_announcement].freeze
  PREVIOUS_TYPES = %w[fight_finished item_found system_information world_announcement].freeze

  def up
    replace_type_constraint(CURRENT_TYPES)
  end

  def down
    replace_type_constraint(PREVIOUS_TYPES)
  end

  private

  def replace_type_constraint(types)
    remove_check_constraint :game_events, name: "game_events_type_check"
    add_check_constraint :game_events,
      "event_type IN (#{types.map { |type| connection.quote(type) }.join(", ")})",
      name: "game_events_type_check"
  end
end
