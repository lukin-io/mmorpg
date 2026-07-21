# frozen_string_literal: true

module Game
  module World
    # Converts an allowlisted interrupted wilderness destination to persisted
    # fight metadata and back to a local route. Arbitrary URLs are never stored
    # or followed.
    class CombatReturnContext
      include Rails.application.routes.url_helpers

      CONTEXTS = %w[world profile inventory].freeze

      class UnsupportedContextError < StandardError; end

      def initialize(character:)
        @character = character
      end

      def normalize(context)
        name = if context.respond_to?(:to_h)
          context.to_h.deep_stringify_keys["name"]
        else
          context
        end.to_s
        name = "world" if name.blank?

        raise UnsupportedContextError, "Unsupported fight return context." unless CONTEXTS.include?(name)

        {"name" => name}
      end

      def path_for(context)
        case normalize(context)["name"]
        when "profile"
          player_path(name: character.name)
        when "inventory"
          inventory_path
        else
          world_path
        end
      rescue UnsupportedContextError
        world_path
      end

      private

      attr_reader :character
    end
  end
end
