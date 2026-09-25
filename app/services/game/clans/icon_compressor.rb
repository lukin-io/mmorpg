# frozen_string_literal: true

module Game
  module Clans
    # Compresses an uploaded clan crest to a small square PNG for the shell UI.
    class IconCompressor
      MAX_BYTES = 2.megabytes
      TARGET_PX = 64
      ALLOWED = %w[image/png image/jpeg image/jpg image/webp image/gif].freeze

      Result = Struct.new(:success, :path, :message, keyword_init: true)

      def initialize(io:, clan_key:)
        @io = io
        @clan_key = clan_key.to_s
      end

      def call
        return fail!(I18n.t("game.clans.icon_missing")) unless io.respond_to?(:read)
        return fail!(I18n.t("game.clans.icon_too_large")) if io.size.to_i > MAX_BYTES

        content_type = io.content_type.to_s.downcase
        return fail!(I18n.t("game.clans.icon_type")) unless ALLOWED.include?(content_type)

        dir = Rails.root.join("public/uploads/clan_icons")
        FileUtils.mkdir_p(dir)
        filename = "#{clan_key}-#{SecureRandom.hex(4)}.png"
        absolute = dir.join(filename)

        pipeline = ImageProcessing::Vips
          .source(io)
          .resize_to_fill(TARGET_PX, TARGET_PX)
          .convert("png")
        pipeline.call(destination: absolute.to_s)

        Result.new(success: true, path: "/uploads/clan_icons/#{filename}", message: nil)
      rescue StandardError => error
        fail!(I18n.t("game.clans.icon_failed", detail: error.message))
      end

      private

      attr_reader :io, :clan_key

      def fail!(message)
        Result.new(success: false, path: nil, message:)
      end
    end
  end
end
