# frozen_string_literal: true

# Purpose: Provides neutral player avatar rendering and explicit NPC images.
#
# NPC avatars use explicit captured config metadata. Monster images such as
# wolf/boar/skeleton/zombie remain available assets, not gameplay selectors.
#
# Usage:
#   # In views:
#   <%= avatar_image_tag(character) %>
#   <%= npc_avatar_image_tag(npc_template) %>
#   <%= avatar_image_tag(participation) %>  # handles both character and NPC
#
module AvatarHelper
  NPC_IMAGE_ASSETS = %w[scarecrow wolf boar skeleton zombie].freeze

  # Renders a neutral fallback avatar for a character until a source-backed
  # player portrait system exists.
  #
  # @param character [Character] the character to render avatar for
  # @param size [Symbol] :small (32px), :medium (48px), :large (64px), :xlarge (96px)
  # @param options [Hash] additional options passed to image_tag
  # @return [ActiveSupport::SafeBuffer] the image tag HTML
  def character_avatar_tag(character, size: :medium, **options)
    return fallback_avatar_tag(size:, **options) unless character

    fallback_avatar_tag(size:, **options)
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
    return fallback_avatar_tag(size:, **options) unless avatar_name

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

  private

  # Determines the NPC avatar name from explicit metadata.
  #
  # @param npc_template [NpcTemplate] the NPC template
  # @return [String] avatar filename (without path, without extension)
  def npc_avatar_name(npc_template)
    image = npc_template.metadata&.dig("avatar_image")
    return if image.blank?

    image.to_s.sub(/\.png\z/, "")
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
