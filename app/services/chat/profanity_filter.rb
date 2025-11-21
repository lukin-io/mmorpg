# frozen_string_literal: true

module Chat
  # Filters chat input for banned words and returns the sanitized text plus metadata.
  #
  # Usage:
  #   filter = Chat::ProfanityFilter.new
  #   result = filter.call("some text")
  #
  # Returns:
  #   Chat::ProfanityFilter::Result with:
  #     - filtered_text: string with profane terms replaced by asterisks
  #     - flagged?: boolean indicating whether any substitutions were made
  class ProfanityFilter
    Result = Struct.new(:filtered_text, :flagged?, keyword_init: true)

    def initialize(dictionary: default_dictionary)
      @dictionary = Array(dictionary).map(&:to_s).reject(&:blank?)
    end

    def call(text)
      return Result.new(filtered_text: "", flagged?: false) if text.blank?

      filtered = text.dup
      flagged = false

      dictionary.each do |word|
        pattern = /\b#{Regexp.escape(word)}\b/i
        next unless filtered.match?(pattern)

        flagged = true
        filtered.gsub!(pattern) { |match| "*" * match.length }
      end

      Result.new(filtered_text: filtered, flagged?: flagged)
    end

    private

    attr_reader :dictionary

    def default_dictionary
      config_path = Rails.root.join("config/chat_profanity.yml")
      if config_path.exist?
        YAML.safe_load(config_path.read, permitted_classes: [], aliases: false).fetch("words", [])
      else
        %w[foo swear curse]
      end
    rescue StandardError
      %w[foo swear curse]
    end
  end
end
