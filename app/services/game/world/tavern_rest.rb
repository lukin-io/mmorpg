# frozen_string_literal: true

module Game
  module World
    # Ashen tavern sit-down: restores HP/MP and clears fatigue. Injuries stay — Infirmary owns those.
    class TavernRest
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(character:)
        @character = character
      end

      def call
        character.with_lock do
          character.reload
          if character.in_combat?
            return Result.new(success: false, message: I18n.t("game.buildings.tavern_in_combat"))
          end

          fatigue = Characters::FatigueService.new(character:)
          fatigue_now = fatigue.current_percent
          max_hp = character.effective_max_hp.to_i
          max_mp = character.effective_max_mp.to_i
          vitals_full = character.current_hp.to_i >= max_hp && character.current_mp.to_i >= max_mp
          if vitals_full && fatigue_now <= 0
            return Result.new(success: false, message: I18n.t("game.buildings.tavern_already_full"))
          end

          character.update!(
            current_hp: max_hp,
            current_mp: max_mp,
            in_combat: false,
            fatigue_percent: 0,
            fatigue_updated_at: Time.current
          )
          Result.new(success: true, message: I18n.t("game.buildings.tavern_rested"))
        end
      end

      private

      attr_reader :character
    end
  end
end
