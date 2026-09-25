# frozen_string_literal: true

class CharacterTimersController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def show
    rows = current_character.dungeon_run_states.order(:pack_key).filter_map do |state|
      next unless state.on_cooldown?

      pack = Game::Instances::DungeonPacks.find(state.pack_key)
      name = pack&.dig("name") || state.pack_key
      seconds = state.seconds_remaining
      {
        name:,
        seconds:,
        label: I18n.t("social.timer_remaining", hours: seconds / 3600, minutes: (seconds % 3600) / 60)
      }
    end

    render json: {
      timers: rows,
      empty: I18n.t("social.timers_empty")
    }
  end
end
