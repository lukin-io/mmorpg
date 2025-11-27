# frozen_string_literal: true

# Chat emoji/smiley conversion
# Converts text codes like :001: to emoji or image tags
#
# @example Find and convert emoji
#   ChatEmoji.find_by(code: "001")&.html
#   # => "<span class='emoji emoji-001'>😀</span>"
#
# @example Convert all codes in text
#   ChatEmoji.convert_all("Hello :001: world :002:")
#   # => "Hello 😀 world 😢"
#
class ChatEmoji
  EMOJI_MAP = {
    # Basic emotions (:NNN: format)
    "001" => { unicode: "😀", name: "happy" },
    "002" => { unicode: "😢", name: "sad" },
    "003" => { unicode: "😂", name: "laugh" },
    "004" => { unicode: "😡", name: "angry" },
    "005" => { unicode: "😱", name: "scared" },
    "006" => { unicode: "😎", name: "cool" },
    "007" => { unicode: "🤔", name: "think" },
    "008" => { unicode: "😉", name: "wink" },
    "009" => { unicode: "😍", name: "love" },
    "010" => { unicode: "🙄", name: "eyeroll" },

    # Combat/RPG themed
    "011" => { unicode: "⚔️", name: "swords" },
    "012" => { unicode: "🛡️", name: "shield" },
    "013" => { unicode: "🏹", name: "bow" },
    "014" => { unicode: "🔥", name: "fire" },
    "015" => { unicode: "❄️", name: "ice" },
    "016" => { unicode: "⚡", name: "lightning" },
    "017" => { unicode: "💀", name: "skull" },
    "018" => { unicode: "💪", name: "strong" },
    "019" => { unicode: "🏆", name: "trophy" },
    "020" => { unicode: "💎", name: "gem" },

    # Game objects
    "021" => { unicode: "🗡️", name: "dagger" },
    "022" => { unicode: "🪓", name: "axe" },
    "023" => { unicode: "🏰", name: "castle" },
    "024" => { unicode: "🐉", name: "dragon" },
    "025" => { unicode: "🧙", name: "mage" },
    "026" => { unicode: "🧝", name: "elf" },
    "027" => { unicode: "🧟", name: "zombie" },
    "028" => { unicode: "👹", name: "demon" },
    "029" => { unicode: "🦊", name: "fox" },
    "030" => { unicode: "🐺", name: "wolf" },

    # Actions
    "031" => { unicode: "👍", name: "thumbsup" },
    "032" => { unicode: "👎", name: "thumbsdown" },
    "033" => { unicode: "👋", name: "wave" },
    "034" => { unicode: "🙏", name: "pray" },
    "035" => { unicode: "✌️", name: "peace" },
    "036" => { unicode: "💔", name: "heartbreak" },
    "037" => { unicode: "💰", name: "money" },
    "038" => { unicode: "⭐", name: "star" },
    "039" => { unicode: "🎉", name: "party" },
    "040" => { unicode: "💤", name: "sleep" },

    # Text shortcuts (common patterns)
    ":)" => { unicode: "🙂", name: "smile" },
    ":(" => { unicode: "😞", name: "frown" },
    ":D" => { unicode: "😄", name: "grin" },
    ":P" => { unicode: "😛", name: "tongue" },
    ";)" => { unicode: "😉", name: "wink" },
    "<3" => { unicode: "❤️", name: "heart" },
    ":O" => { unicode: "😮", name: "surprised" },
    "XD" => { unicode: "🤣", name: "rofl" },
    ":/" => { unicode: "😕", name: "confused" },
    ":|" => { unicode: "😐", name: "neutral" }
  }.freeze

  attr_reader :code, :unicode, :name

  def initialize(code:, unicode:, name:)
    @code = code
    @unicode = unicode
    @name = name
  end

  # Find emoji by code
  #
  # @param code [String] the emoji code (e.g., "001" or ":)")
  # @return [ChatEmoji, nil] the emoji or nil if not found
  def self.find_by(code:)
    data = EMOJI_MAP[code]
    return nil unless data

    new(code: code, unicode: data[:unicode], name: data[:name])
  end

  # Get all available emojis
  #
  # @return [Array<ChatEmoji>] all emojis
  def self.all
    EMOJI_MAP.map do |code, data|
      new(code: code, unicode: data[:unicode], name: data[:name])
    end
  end

  # Get emojis by category (numeric codes only)
  #
  # @return [Array<ChatEmoji>] emojis with numeric codes
  def self.picker_emojis
    EMOJI_MAP.select { |code, _| code.match?(/^\d{3}$/) }
      .map { |code, data| new(code: code, unicode: data[:unicode], name: data[:name]) }
  end

  # Convert all emoji codes in text
  #
  # @param text [String] text containing emoji codes
  # @return [String] text with codes replaced by emoji
  def self.convert_all(text)
    return text if text.blank?

    result = text.dup

    # Convert :NNN: codes
    result.gsub!(/:(\d{3}):/) do |match|
      find_by(code: ::Regexp.last_match(1))&.unicode || match
    end

    # Convert text shortcuts
    EMOJI_MAP.each do |code, data|
      next if code.match?(/^\d{3}$/) # Skip numeric codes, already handled

      result.gsub!(code, data[:unicode])
    end

    result
  end

  # Get HTML representation
  #
  # @return [String] HTML span with emoji
  def html
    "<span class=\"emoji emoji-#{name}\" title=\"#{name}\">#{unicode}</span>"
  end

  # Get the display string (just unicode)
  #
  # @return [String] the unicode emoji
  def to_s
    unicode
  end
end
