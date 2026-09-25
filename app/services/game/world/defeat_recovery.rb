# frozen_string_literal: true

module Game
  module World
    # After a lost fight, recover the character into the city hospital so a
    # death does not soft-lock the outdoor loop at 0 HP.
    class DefeatRecovery
      include Rails.application.routes.url_helpers

      Result = Struct.new(:recovered, :path, :message, keyword_init: true)

      def initialize(character:)
        @character = character
      end

      def call
        character.with_lock do
          character.reload
          return Result.new(recovered: false) if character.current_hp.to_i.positive?

          max_hp = character.effective_max_hp.to_i
          max_mp = character.effective_max_mp.to_i
          character.update!(
            current_hp: [max_hp, 1].max,
            current_mp: [max_mp, 0].max,
            in_combat: false
          )

          relocate_to_city_hospital!
          ResumeContext.new(character:).remember_city_building!(building_key: "hospital")

          Result.new(
            recovered: true,
            path: city_building_path("hospital", defeat_recovered: 1),
            message: I18n.t("game.flashes.defeat_hospital_recovery")
          )
        end
      end

      private

      attr_reader :character

      def relocate_to_city_hospital!
        city = starter_city_zone
        return unless city

        position = character.position || character.create_position!(
          zone: city,
          x: 0,
          y: 0,
          state: :active
        )
        position.update!(zone: city, x: 0, y: 0, state: :active, last_action_at: Time.current)
        Chat::LocalContext.new(character:).synchronize!
      end

      def starter_city_zone
        node = CityCatalog.node(CityCatalog::STARTER_NODE_KEY)
        Zone.find_by(name: node["zone_name"]) if node
      end
    end
  end
end
