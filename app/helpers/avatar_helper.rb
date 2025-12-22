# frozen_string_literal: true

# Purpose: Provides avatar image rendering for players and NPCs
#
# Player avatars are assigned randomly on character creation and stored in DB.
# NPC avatars are determined by their type/config (arena bots use scarecrow,
# open world NPCs use appropriate monster images).
#
# Usage:
#   # In views:
#   <%= avatar_image_tag(character) %>
#   <%= npc_avatar_image_tag(npc_template) %>
#   <%= avatar_image_tag(participation) %>  # handles both character and NPC
#
module AvatarHelper
  # Available player avatars (randomly assigned on character creation)
  PLAYER_AVATARS = %w[
    dwarven
    nightveil
    lightbearer
    pathfinder
    arcanist
    ironbound
  ].freeze

  # NPC avatar mappings by key pattern or role
  NPC_AVATARS = {
    # Arena bots use scarecrow
    arena_bot: "scarecrow",

    # Open world hostile NPCs by key pattern
    wolf: "wolf",
    boar: "boar",
    skeleton: "skeleton",
    zombie: "zombie",

    # Default fallback
    default: "skeleton"
  }.freeze

  # Open world NPC avatar keys (excludes arena scarecrow)
  OPEN_WORLD_NPC_AVATARS = %w[wolf boar skeleton zombie].freeze

  # Renders an avatar image tag for a character
  #
  # @param character [Character] the character to render avatar for
  # @param size [Symbol] :small (32px), :medium (48px), :large (64px), :xlarge (96px)
  # @param options [Hash] additional options passed to image_tag
  # @return [ActiveSupport::SafeBuffer] the image tag HTML
  def character_avatar_tag(character, size: :medium, **options)
    return fallback_avatar_tag(size:, **options) unless character

    avatar_name = character.avatar.presence || random_player_avatar
    avatar_path = "avatars/#{avatar_name}.png"

    build_avatar_tag(avatar_path, character.name, size:, **options)
  end

  # Renders an avatar image tag for an NPC
  #
  # @param npc_template [NpcTemplate] the NPC template to render avatar for
  # @param size [Symbol] :small (32px), :medium (48px), :large (64px), :xlarge (96px)
  # @param options [Hash] additional options passed to image_tag
  # @return [ActiveSupport::SafeBuffer] the image tag HTML
  def npc_avatar_tag(npc_template, size: :medium, **options)
    return fallback_avatar_tag(size:, **options) unless npc_template

    avatar_name = npc_avatar_name(npc_template)
    avatar_path = "npc/#{avatar_name}.png"

    build_avatar_tag(avatar_path, npc_template.name, size:, css_class: "npc-avatar", **options)
  end

  # Renders avatar for an ArenaParticipation (handles both character and NPC)
  #
  # @param participation [ArenaParticipation] the participation record
  # @param size [Symbol] :small, :medium, :large, :xlarge
  # @param options [Hash] additional options passed to image_tag
  # @return [ActiveSupport::SafeBuffer] the image tag HTML
  def participation_avatar_tag(participation, size: :medium, **options)
    return fallback_avatar_tag(size:, **options) unless participation

    if participation.npc_template.present?
      npc_avatar_tag(participation.npc_template, size:, **options)
    elsif participation.character.present?
      character_avatar_tag(participation.character, size:, **options)
    else
      fallback_avatar_tag(size:, **options)
    end
  end

  # Renders avatar for a BattleParticipant (handles both character and NPC)
  #
  # @param participant [BattleParticipant] the battle participant record
  # @param size [Symbol] :small, :medium, :large, :xlarge
  # @param options [Hash] additional options passed to image_tag
  # @return [ActiveSupport::SafeBuffer] the image tag HTML
  def battle_participant_avatar_tag(participant, size: :medium, **options)
    return fallback_avatar_tag(size:, **options) unless participant

    if participant.npc_template.present?
      npc_avatar_tag(participant.npc_template, size:, **options)
    elsif participant.character.present?
      character_avatar_tag(participant.character, size:, **options)
    else
      fallback_avatar_tag(size:, **options)
    end
  end

  # Get a random player avatar name
  #
  # @return [String] random avatar filename (without extension)
  def random_player_avatar
    PLAYER_AVATARS.sample
  end

  # Get list of all available player avatars
  #
  # @return [Array<String>] array of avatar names
  def available_player_avatars
    PLAYER_AVATARS.dup
  end

  private

  # Determines the NPC avatar name based on template
  #
  # @param npc_template [NpcTemplate] the NPC template
  # @return [String] avatar filename (without path, without extension)
  def npc_avatar_name(npc_template)
    # Check for explicit avatar_image in metadata first
    if npc_template.metadata&.dig("avatar_image").present?
      # Remove .png extension if present for consistency
      return npc_template.metadata["avatar_image"].to_s.sub(/\.png\z/, "")
    end

    # Arena bots use scarecrow
    return "scarecrow" if npc_template.role == "arena_bot"

    # Try to match NPC key to avatar
    npc_key = npc_template.npc_key.to_s.downcase

    # Check for pattern matches in key
    OPEN_WORLD_NPC_AVATARS.each do |avatar|
      return avatar if npc_key.include?(avatar)
    end

    # Default fallback based on role or random open world avatar
    if npc_template.hostile?
      OPEN_WORLD_NPC_AVATARS.sample
    else
      NPC_AVATARS[:default]
    end
  end

  # Builds the actual image tag with proper sizing and CSS classes
  #
  # @param path [String] asset path for the image
  # @param alt [String] alt text for the image
  # @param size [Symbol] size preset
  # @param css_class [String] additional CSS class
  # @param options [Hash] additional options for image_tag
  # @return [ActiveSupport::SafeBuffer] the image tag HTML
  def build_avatar_tag(path, alt, size:, css_class: nil, **options)
    dimensions = avatar_dimensions(size)
    classes = ["avatar", "avatar--#{size}", css_class].compact.join(" ")

    # Merge with any existing class option
    existing_class = options.delete(:class)
    full_class = [classes, existing_class].compact.join(" ")

    image_tag(
      path,
      alt: alt,
      width: dimensions,
      height: dimensions,
      class: full_class,
      loading: "lazy",
      **options
    )
  end

  # Returns pixel dimensions for avatar size presets
  #
  # @param size [Symbol] :small, :medium, :large, :xlarge
  # @return [Integer] pixel dimension
  def avatar_dimensions(size)
    case size
    when :small then 32
    when :medium then 48
    when :large then 64
    when :xlarge then 96
    else 48
    end
  end

  # Renders a fallback avatar for missing data
  #
  # @param size [Symbol] size preset
  # @param options [Hash] additional options
  # @return [ActiveSupport::SafeBuffer] the fallback element
  def fallback_avatar_tag(size: :medium, **options)
    dimensions = avatar_dimensions(size)
    classes = ["avatar", "avatar--#{size}", "avatar--fallback", options[:class]].compact.join(" ")

    content_tag(:span, "👤", class: classes, style: "font-size: #{dimensions / 2}px; line-height: #{dimensions}px;")
  end
end
