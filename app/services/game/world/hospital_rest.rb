# frozen_string_literal: true

module Game
  module World
    # Free Ashen hospital rest: restores HP/MP and clears light/heavy injuries.
    # Combat trauma from PvP combat scrolls is not cleared here.
    class HospitalRest
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(character:)
        @character = character
      end

      def call
        character.with_lock do
          character.reload
          if character.in_combat?
            return Result.new(success: false, message: I18n.t("game.buildings.hospital_in_combat"))
          end

          injuries = Game::Combat::InjuryState.new(character:)
          max_hp = character.effective_max_hp.to_i
          max_mp = character.effective_max_mp.to_i
          needs_vitals = character.current_hp.to_i < max_hp || character.current_mp.to_i < max_mp
          ordinary = injuries.active.any? { |row| %w[light heavy].include?(row["severity"].to_s) }
          combat_left = injuries.active.any? { |row| row["severity"].to_s == "combat" }

          if !needs_vitals && !ordinary
            message =
              if combat_left
                I18n.t("game.buildings.hospital_combat_only")
              else
                I18n.t("game.buildings.hospital_already_full")
              end
            return Result.new(success: false, message:)
          end

          character.update!(current_hp: max_hp, current_mp: max_mp, in_combat: false)
          injuries.clear_non_combat!
          still_combat = Game::Combat::InjuryState.new(character: character.reload).active.any? do |row|
            row["severity"].to_s == "combat"
          end
          message =
            if still_combat
              I18n.t("game.buildings.hospital_rested_combat_remains")
            elsif ordinary
              I18n.t("game.buildings.hospital_rested_injuries")
            else
              I18n.t("game.buildings.hospital_rested")
            end
          Result.new(success: true, message:)
        end
      end

      private

      attr_reader :character
    end
  end
end
