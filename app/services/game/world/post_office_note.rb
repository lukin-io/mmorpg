# frozen_string_literal: true

module Game
  module World
    # Sandbox Ashen mailbox: one personal note stored on character metadata.
    class PostOfficeNote
      Result = Struct.new(:success, :message, :note, keyword_init: true)
      META_KEY = "ashen_post_note"
      MAX_LEN = 280

      def initialize(character:, body: nil)
        @character = character
        @body = body
      end

      def self.current_for(character)
        character.metadata.to_h[META_KEY].to_s
      end

      def save!
        text = body.to_s.strip
        return failure(I18n.t("game.buildings.post_blank")) if text.blank?
        return failure(I18n.t("game.buildings.post_too_long", max: MAX_LEN)) if text.length > MAX_LEN

        character.with_lock do
          character.reload
          character.update!(metadata: character.metadata.to_h.merge(META_KEY => text))
        end
        Result.new(success: true, note: text, message: I18n.t("game.buildings.post_saved"))
      end

      def clear!
        character.with_lock do
          character.reload
          metadata = character.metadata.to_h
          return failure(I18n.t("game.buildings.post_empty")) if metadata[META_KEY].to_s.blank?

          character.update!(metadata: metadata.except(META_KEY))
        end
        Result.new(success: true, note: "", message: I18n.t("game.buildings.post_cleared"))
      end

      private

      attr_reader :character, :body

      def failure(message)
        Result.new(success: false, message:, note: self.class.current_for(character))
      end
    end
  end
end
