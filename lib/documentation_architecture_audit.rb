# frozen_string_literal: true

require "pathname"

# Validates objective documentation ownership and link integrity without
# enforcing prose, a frozen file inventory, or workflow metadata.
module DocumentationArchitectureAudit
  DOMAINS = %w[
    shell
    social
    character
    inventory
    world
    city
    economy
    combat
    npcs_quests
    professions
    dungeons
  ].freeze

  COMPATIBILITY_ALIASES = {
    "doc/design/reference/neverlands_chat.md" =>
      "doc/design/reference/social/observations/legacy_chat_system_analysis.md",
    "doc/design/reference/neverlands_live_city_movement.md" =>
      "doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md",
    "doc/design/reference/neverlands_live_game_shell_ui.md" =>
      "doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md",
    "doc/design/reference/neverlands_live_inventory_items.md" =>
      "doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md",
    "doc/design/reference/neverlands_live_lavka_shop.md" =>
      "doc/design/reference/economy/observations/2026-05-21_lavka_shop.md",
    "doc/design/reference/neverlands_live_movement.md" =>
      "doc/design/reference/world/observations/2026-05-09_overworld_movement.md",
    "doc/design/reference/neverlands_live_outdoor_npc_resource.md" =>
      "doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md",
    "doc/design/reference/neverlands_live_player.md" =>
      "doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md",
    "doc/design/reference/neverlands_live_style_system.md" =>
      "doc/design/reference/shell/observations/2026-07-29_style_system.md",
    "doc/design/reference/neverlands_skills.md" =>
      "doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md"
  }.freeze

  REQUIRED_ENTRY_POINTS = %w[
    doc/README.md
    doc/DOCUMENTATION.md
    doc/domains/README.md
    doc/design/reference/README.md
    doc/templates/README.md
    doc/templates/DOMAIN_INDEX_TEMPLATE.md
    doc/templates/NEVERLANDS_SOURCE_SUMMARY_TEMPLATE.md
    doc/templates/NEVERLANDS_OBSERVATION_TEMPLATE.md
    doc/templates/DESIGN_PLACEHOLDER_TEMPLATE.md
    doc/features/README.md
    doc/features/FEATURE_TEMPLATE.md
    doc/features/NOT_IMPLEMENTED_TEMPLATE.md
  ].freeze

  REPOSITORY_PATH_PATTERN =
    /`((?:(?:app|bin|changelogs|config|db|doc|lib|spec|\.github)\/[^`\s]+|AGENTS?\.md|README\.md))`/
  MARKDOWN_DOC_LINK_PATTERN = /\]\((?!https?:|mailto:|#)([^)]+\.md(?:#[^)]+)?)\)/
  UNRESOLVED_PATH_PATTERN = /[\[\]<>*{}]/

  Result = Data.define(:documents_count, :errors) do
    def success?
      errors.empty?
    end
  end

  class Auditor
    def initialize(root:, domains: DOMAINS, compatibility_aliases: COMPATIBILITY_ALIASES)
      @root = Pathname(root).expand_path
      @domains = domains
      @compatibility_aliases = compatibility_aliases
      @errors = []
      @audited_documents = []
    end

    def call
      audit_entry_points
      audit_domain_registry
      audit_domains
      audit_placeholders
      audit_compatibility_aliases
      audit_repository_paths

      Result.new(documents_count: audited_documents.uniq.length, errors:)
    end

    private

    attr_reader :root, :domains, :compatibility_aliases, :errors, :audited_documents

    def audit_entry_points
      REQUIRED_ENTRY_POINTS.each { |path| require_file(path) }
    end

    def audit_domain_registry
      registry = require_file("doc/domains/README.md")
      reference_registry = require_file("doc/design/reference/README.md")

      domains.each do |domain|
        require_unique_reference(
          "doc/domains/README.md",
          registry,
          "doc/domains/#{domain}.md"
        )
        require_unique_reference(
          "doc/design/reference/README.md",
          reference_registry,
          "doc/design/reference/#{domain}/README.md"
        )
      end
    end

    def audit_domains
      domains.each do |domain|
        domain_path = "doc/domains/#{domain}.md"
        summary_path = "doc/design/reference/#{domain}/README.md"
        observations_path = root.join("doc/design/reference", domain, "observations")

        domain_content = require_file(domain_path)
        summary_content = require_file(summary_path)

        require_content(domain_path, domain_content, summary_path)
        unless domain_content.match?(/`doc\/features\/[a-z0-9_]+\.md`/)
          errors << "#{domain_path}: at least one feature-handbook owner is required"
        end
        require_content(summary_path, summary_content, "Domain: #{domain}")

        unless observations_path.directory?
          errors << "#{relative_path(observations_path)}: observations directory is required"
          next
        end

        observations_path.glob("*.md").sort.each { |path| read_file(path) }
      end
    end

    def audit_placeholders
      root.glob("doc/design/reference/**/observations/*evidence_needed*.md").sort.each do |path|
        content = read_file(path)
        require_content(relative_path(path), content, "Evidence status: EVIDENCE_NEEDED")
      end

      root.glob("doc/design/**/*design_needed*.md").sort.each do |path|
        content = read_file(path)
        require_content(relative_path(path), content, "DESIGN_NEEDED")
      end
    end

    def audit_compatibility_aliases
      compatibility_aliases.each do |alias_path, canonical_path|
        content = require_file(alias_path)
        require_file(canonical_path)
        require_content(alias_path, content, canonical_path)
      end
    end

    def audit_repository_paths
      audited_documents.uniq.each do |document|
        content = read_file(document)

        content.scan(REPOSITORY_PATH_PATTERN).flatten.uniq.each do |path|
          audit_root_relative_path(document, path)
        end

        content.scan(MARKDOWN_DOC_LINK_PATTERN).flatten.uniq.each do |link|
          audit_markdown_link(document, link)
        end
      end
    end

    def audit_root_relative_path(document, path)
      return if path.match?(UNRESOLVED_PATH_PATTERN)
      return if root.join(path).exist?

      errors << "#{relative_path(document)}: referenced repository path does not exist: #{path}"
    end

    def audit_markdown_link(document, link)
      path = link.sub(/#.*/, "")
      return if path.empty? || path.match?(UNRESOLVED_PATH_PATTERN)

      destination = if path.start_with?("doc/", "README.md", "AGENTS.md")
        root.join(path)
      else
        document.dirname.join(path).cleanpath
      end
      return if destination.file?

      errors << "#{relative_path(document)}: referenced Markdown document does not exist: #{link}"
    end

    def require_unique_reference(path, content, expected)
      count = content.scan(expected).length
      return if count == 1

      errors << "#{path}: expected exactly one reference to #{expected}, found #{count}"
    end

    def require_file(path)
      document = resolve_path(path)
      unless document.file?
        errors << "#{relative_path(document)}: document does not exist"
        return ""
      end

      read_file(document)
    end

    def read_file(document)
      resolved = resolve_path(document)
      audited_documents << resolved
      resolved.file? ? resolved.read : ""
    end

    def require_content(path, content, expected)
      return if content.include?(expected)

      errors << "#{relative_path(resolve_path(path))}: required content missing: #{expected}"
    end

    def resolve_path(path)
      candidate = Pathname(path)
      candidate.absolute? ? candidate : root.join(candidate)
    end

    def relative_path(path)
      resolve_path(path).relative_path_from(root).to_s
    rescue ArgumentError
      path.to_s
    end
  end
end
