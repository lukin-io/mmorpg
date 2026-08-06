# frozen_string_literal: true

require "pathname"

# Validates the domain-first documentation registry and its links without
# loading Rails or mutating repository files.
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

  BASELINE_DOC_PATHS = %w[
    doc/DOCUMENTATION.md
    doc/README.md
    doc/RUBY_ON_RAILS_GUIDE.md
    doc/UI.md
    doc/design/README.md
    doc/design/gdd.md
    doc/design/launch_mvp_plan.md
    doc/design/areas/arena.md
    doc/design/areas/cities_and_buildings.md
    doc/design/areas/game_client_layout.md
    doc/design/areas/world_map.md
    doc/design/features/character_vitals.md
    doc/design/features/combat.md
    doc/design/features/dungeons.md
    doc/design/features/economy_trading_shops.md
    doc/design/features/items_inventory_equipment.md
    doc/design/features/movement.md
    doc/design/features/npcs_quests.md
    doc/design/features/professions.md
    doc/design/features/progression_stats_skills.md
    doc/design/features/social_chat_presence.md
    doc/design/reference/neverlands.md
    doc/design/reference/neverlands_chat.md
    doc/design/reference/neverlands_live_city_movement.md
    doc/design/reference/neverlands_live_game_shell_ui.md
    doc/design/reference/neverlands_live_inventory_items.md
    doc/design/reference/neverlands_live_lavka_shop.md
    doc/design/reference/neverlands_live_movement.md
    doc/design/reference/neverlands_live_outdoor_npc_resource.md
    doc/design/reference/neverlands_live_player.md
    doc/design/reference/neverlands_live_style_system.md
    doc/design/reference/neverlands_skills.md
    doc/design/reference/source_material.md
    doc/features/FEATURE_TEMPLATE.md
    doc/features/README.md
    doc/features/arena_combat.md
    doc/features/character_progression.md
    doc/features/city.md
    doc/features/game_shell.md
    doc/features/player_inventory.md
    doc/features/shop_economy.md
    doc/features/world.md
    doc/guides/managing_game_content.md
  ].freeze

  IMPLEMENTATION_PLACEHOLDERS = %w[
    doc/features/quests.md
    doc/features/professions.md
    doc/features/dungeons.md
  ].freeze

  EVIDENCE_PLACEHOLDERS = %w[
    doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md
    doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md
    doc/design/reference/dungeons/observations/evidence_needed_dungeon_flow.md
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

  REPOSITORY_PATH_PATTERN = /`((?:(?:app|bin|config|db|doc|lib|spec)\/[^`\s]+|AGENT\.md|README\.md))`/
  PARITY_ID_PATTERN = /`([A-Z][A-Z0-9_-]+-\d{3})`/
  UNRESOLVED_PATH_PATTERN = /[\[\]<>*{}]/

  Result = Data.define(:documents_count, :errors) do
    def success?
      errors.empty?
    end
  end

  class Auditor
    def initialize(
      root:,
      domains: DOMAINS,
      baseline_paths: BASELINE_DOC_PATHS,
      implementation_placeholders: IMPLEMENTATION_PLACEHOLDERS,
      evidence_placeholders: EVIDENCE_PLACEHOLDERS,
      compatibility_aliases: COMPATIBILITY_ALIASES
    )
      @root = Pathname(root).expand_path
      @domains = domains
      @baseline_paths = baseline_paths
      @implementation_placeholders = implementation_placeholders
      @evidence_placeholders = evidence_placeholders
      @compatibility_aliases = compatibility_aliases
      @errors = []
      @audited_documents = []
    end

    def call
      audit_architecture_entry_points
      audit_domains
      audit_placeholders
      audit_compatibility_aliases
      audit_baseline_manifest
      audit_repository_paths

      Result.new(documents_count: audited_documents.uniq.length, errors:)
    end

    private

    attr_reader :root, :domains, :baseline_paths, :implementation_placeholders,
      :evidence_placeholders, :compatibility_aliases, :errors, :audited_documents

    def audit_architecture_entry_points
      %w[
        doc/DOCUMENTATION.md
        doc/DOCUMENTATION_MIGRATION_MANIFEST.md
        doc/templates/README.md
        doc/templates/DOMAIN_INDEX_TEMPLATE.md
        doc/templates/NEVERLANDS_SOURCE_SUMMARY_TEMPLATE.md
        doc/templates/NEVERLANDS_OBSERVATION_TEMPLATE.md
        doc/templates/DESIGN_PLACEHOLDER_TEMPLATE.md
        doc/features/NOT_IMPLEMENTED_TEMPLATE.md
      ].each { |path| require_file(path) }

      domain_registry = require_file("doc/domains/README.md")
      reference_registry = require_file("doc/design/reference/README.md")
      domains.each do |domain|
        require_content("doc/domains/README.md", domain_registry, "doc/domains/#{domain}.md")
        require_content(
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

        audit_domain_index(domain_path, domain, summary_path, domain_content)
        audit_source_document(summary_path, domain, summary_content)

        unless observations_path.directory?
          errors << "#{relative_path(observations_path)}: observations directory is required"
          next
        end

        observations_path.glob("*.md").sort.each do |observation|
          content = read_file(observation)
          audit_source_document(relative_path(observation), domain, content)
        end
      end
    end

    def audit_domain_index(path, domain, summary_path, content)
      require_content(path, content, "## Documentation chain")
      require_content(path, content, "## Current RPG status")
      require_content(path, content, "## Important responsible implementation files")
      require_content(path, content, summary_path)
      require_content(path, content, "doc/design/launch_mvp_plan.md")
      audit_parity_ids(path, content)
      errors << "#{path}: domain name #{domain.inspect} is not represented" unless path.include?(domain)
    end

    def audit_parity_ids(path, content)
      parity_ids = content.scan(PARITY_ID_PATTERN).flatten.uniq
      if parity_ids.empty?
        errors << "#{path}: at least one stable parity ID is required"
        return
      end

      parity_plan = require_file("doc/design/launch_mvp_plan.md")
      parity_ids.each { |parity_id| require_content(path, parity_plan, "`#{parity_id}`") }
    end

    def audit_source_document(path, domain, content)
      require_content(path, content, "Domain: #{domain}")
      require_content(path, content, "## Local Implementation Linkage")
      unless content.match?(/Responsible[^\n]*files/i)
        errors << "#{path}: responsible implementation-file context is required"
      end
      unless content.match?(/Local implementation linkage.*?context.*?Neverlands evidence/im)
        errors << "#{path}: local linkage must be labeled as context, not Neverlands evidence"
      end
    end

    def audit_placeholders
      implementation_placeholders.each do |path|
        content = require_file(path)
        require_content(path, content, "status: NOT_IMPLEMENTED")
        require_content(path, content, "## 16. Responsible for Implementation Files")
      end

      evidence_placeholders.each do |path|
        content = require_file(path)
        require_content(path, content, "Evidence status: EVIDENCE_NEEDED")
        require_content(path, content, "## Local Implementation Linkage")
      end
    end

    def audit_compatibility_aliases
      compatibility_aliases.each do |alias_path, canonical_path|
        content = require_file(alias_path)
        require_file(canonical_path)
        require_content(alias_path, content, canonical_path)
      end
    end

    def audit_baseline_manifest
      path = "doc/DOCUMENTATION_MIGRATION_MANIFEST.md"
      content = require_file(path)
      baseline_paths.each { |baseline_path| require_content(path, content, baseline_path) }
      require_content(path, content, "#{baseline_paths.length} of #{baseline_paths.length}")
    end

    def audit_repository_paths
      audited_documents.uniq.each do |document|
        read_file(document).scan(REPOSITORY_PATH_PATTERN).flatten.uniq.each do |referenced_path|
          next if referenced_path.match?(UNRESOLVED_PATH_PATTERN)
          next if root.join(referenced_path).exist?

          errors << "#{relative_path(document)}: referenced repository path does not exist: #{referenced_path}"
        end
      end
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
