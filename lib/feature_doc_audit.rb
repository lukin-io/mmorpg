# frozen_string_literal: true

require "pathname"

# Performs small, objective integrity checks for feature handbooks without
# loading Rails or treating documentation format as workflow state.
module FeatureDocAudit
  SHIPPED_TEMPLATE_ID = "feature-v3"
  GAP_TEMPLATE_ID = "feature-gap-v2"
  LEGACY_TEMPLATE_IDS = %w[feature-v1 feature-v2].freeze
  SUPPORTED_TEMPLATE_IDS = ([SHIPPED_TEMPLATE_ID, GAP_TEMPLATE_ID] + LEGACY_TEMPLATE_IDS).freeze
  FULLY_IMPLEMENTED_STATUS = "Fully Implemented"
  NOT_IMPLEMENTED_STATUS = "NOT_IMPLEMENTED"
  ALLOWED_STATUSES = [
    FULLY_IMPLEMENTED_STATUS,
    "Implemented MVP",
    "Partially Implemented",
    NOT_IMPLEMENTED_STATUS
  ].freeze

  SHIPPED_SECTIONS = [
    "## 1. Authority and scope",
    "## 2. Player contract and non-goals",
    "## 3. Authoritative state and content",
    "## 4. Rails and Hotwire flow",
    "## 5. Security, concurrency, and failure behavior",
    "## 6. Acceptance and tests",
    "## 7. Responsible files and operations",
    "## 8. Gaps and version history"
  ].freeze

  GAP_SECTIONS = [
    "## 1. Evidence and design",
    "## 2. Missing runtime contract",
    "## 3. Existing related handoffs",
    "## 4. Prerequisites for implementation",
    "## 5. Responsible documentation and history"
  ].freeze

  DOCUMENT_EXCLUSIONS = %w[
    FEATURE_TEMPLATE.md
    NOT_IMPLEMENTED_TEMPLATE.md
    README.md
  ].freeze

  DOC_PATH_PATTERN = /\`(doc\/[a-zA-Z0-9_.\/-]+\.md)\`/
  REPOSITORY_PATH_PATTERN = /\`((?:app|bin|config|db|doc|lib|spec)\/[^\`\s]+)\`/
  RUNTIME_PATH_PATTERN = /\`((?:app|bin|config|db|lib|spec)\/[^\`\s]+)\`/
  TEMPLATE_PATHS = %w[
    doc/features/FEATURE_TEMPLATE.md
    doc/features/NOT_IMPLEMENTED_TEMPLATE.md
  ].freeze
  PLACEHOLDER_PATTERNS = [
    /<feature_name>/,
    /YYYY-MM-DD/,
    /Template instruction/i,
    /> Copy this file/
  ].freeze

  Result = Struct.new(:documents_count, :errors, :warnings, keyword_init: true) do
    def success?
      errors.empty?
    end
  end

  class Auditor
    def initialize(root:, paths: [], strict: false)
      @root = Pathname(root).expand_path
      @paths = Array(paths)
      @strict = strict
      @errors = []
      @warnings = []
    end

    def call
      documents = documents_to_audit
      metadata_by_path = documents.to_h do |document|
        content = read_document(document)
        [document, audit_document(document, content)]
      end

      audit_duplicate_titles(metadata_by_path)

      Result.new(
        documents_count: documents.length,
        errors: errors,
        warnings: warnings
      )
    end

    private

    attr_reader :root, :paths, :strict, :errors, :warnings

    def documents_to_audit
      documents = if paths.empty?
        root.join("doc/features").glob("*.md").reject do |document|
          DOCUMENT_EXCLUSIONS.include?(document.basename.to_s)
        end
      else
        paths.map { |path| resolve_path(path) }
      end

      documents.sort_by(&:to_s)
    end

    def resolve_path(path)
      candidate = Pathname(path)
      candidate.absolute? ? candidate : root.join(candidate)
    end

    def read_document(document)
      return document.read if document.file?

      errors << "#{display_path(document)}: document does not exist"
      ""
    end

    def audit_document(document, content)
      metadata = parse_frontmatter(document, content)
      audit_metadata(document, metadata)
      audit_whitespace(document, content)
      audit_layout(document, content, metadata)
      audit_placeholders(document, content, metadata)
      audit_document_links(document, content)
      audit_responsible_paths(document, content, metadata)
      audit_gap_claims(document, content, metadata)
      metadata
    end

    def parse_frontmatter(document, content)
      lines = content.lines
      start_index = lines.first&.strip == "# frozen_string_literal: true" ? 1 : 0

      unless lines[start_index]&.strip == "---"
        errors << "#{display_path(document)}: YAML metadata opening delimiter is missing"
        return {}
      end

      closing_index = lines.each_index.drop(start_index + 1).find do |index|
        lines[index].strip == "---"
      end
      unless closing_index
        errors << "#{display_path(document)}: YAML metadata closing delimiter is missing"
        return {}
      end

      lines[(start_index + 1)...closing_index].each_with_object({}) do |line, metadata|
        key, value = line.split(":", 2)
        next if key.to_s.strip.empty?

        metadata[key.strip] = unquote(value.to_s.strip)
      end
    end

    def unquote(value)
      if value.length >= 2 && ["\"", "'"].include?(value[0]) && value[-1] == value[0]
        value[1...-1]
      else
        value
      end
    end

    def audit_metadata(document, metadata)
      %w[title description status updated owners template].each do |key|
        errors << "#{display_path(document)}: metadata #{key} is required" if metadata[key].to_s.empty?
      end

      unless ALLOWED_STATUSES.include?(metadata["status"])
        errors << "#{display_path(document)}: unsupported status #{metadata['status'].inspect}"
      end

      unless metadata["updated"].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        errors << "#{display_path(document)}: updated must use YYYY-MM-DD"
      end

      template = metadata["template"]
      unless template.to_s.empty? || SUPPORTED_TEMPLATE_IDS.include?(template)
        errors << "#{display_path(document)}: unsupported template #{template.inspect}"
      end

      if metadata["status"] == NOT_IMPLEMENTED_STATUS && template != GAP_TEMPLATE_ID
        errors << "#{display_path(document)}: NOT_IMPLEMENTED documents must use #{GAP_TEMPLATE_ID}"
      elsif template == GAP_TEMPLATE_ID && metadata["status"] != NOT_IMPLEMENTED_STATUS
        errors << "#{display_path(document)}: #{GAP_TEMPLATE_ID} requires NOT_IMPLEMENTED status"
      elsif template == SHIPPED_TEMPLATE_ID && metadata["status"] == NOT_IMPLEMENTED_STATUS
        errors << "#{display_path(document)}: #{SHIPPED_TEMPLATE_ID} cannot claim NOT_IMPLEMENTED"
      end

      if LEGACY_TEMPLATE_IDS.include?(template)
        message = "#{display_path(document)}: legacy #{template} handbook; migrate only when materially useful"
        errors << message if strict
      end

      if ALLOWED_STATUSES.include?(metadata["status"]) &&
          metadata["status"] != FULLY_IMPLEMENTED_STATUS &&
          metadata["status"] != NOT_IMPLEMENTED_STATUS
        warnings << "#{display_path(document)}: #{metadata['status']} is intentionally non-green"
      end
    end

    def audit_whitespace(document, content)
      content.lines.each_with_index do |line, index|
        if line.match?(/[ \t]+$/)
          errors << "#{display_path(document)}:#{index + 1}: trailing whitespace"
        end
      end
    end

    def audit_layout(document, content, metadata)
      expected = case metadata["template"]
      when SHIPPED_TEMPLATE_ID then SHIPPED_SECTIONS
      when GAP_TEMPLATE_ID then GAP_SECTIONS
      end
      return unless expected

      actual = content.lines.grep(/^## \d+\./).map(&:strip)
      return if actual == expected

      errors << "#{display_path(document)}: sections must match #{metadata['template']} template exactly"
    end

    def audit_placeholders(document, content, metadata)
      return unless [SHIPPED_TEMPLATE_ID, GAP_TEMPLATE_ID].include?(metadata["template"])

      matches = placeholder_tokens.select { |token| content.include?(token) }
      matches.concat(PLACEHOLDER_PATTERNS.filter_map { |pattern| content[pattern] })
      matches.uniq!
      return if matches.empty?

      errors << "#{display_path(document)}: unresolved template placeholders: #{matches.first(5).join(', ')}"
    end

    def placeholder_tokens
      @placeholder_tokens ||= TEMPLATE_PATHS.flat_map do |path|
        template = root.join(path)
        template.file? ? template.read.scan(/\[[^\]\n]+\]/) : []
      end.uniq
    end

    def audit_document_links(document, content)
      content.scan(DOC_PATH_PATTERN).flatten.uniq.each do |path|
        next if root.join(path).file?

        errors << "#{display_path(document)}: referenced document does not exist: #{path}"
      end
    end

    def audit_responsible_paths(document, content, metadata)
      section = responsible_section(content, metadata["template"])
      return unless section

      referenced_paths = section.scan(REPOSITORY_PATH_PATTERN).flatten.uniq
      if referenced_paths.empty?
        errors << "#{display_path(document)}: responsible-file section has no repository paths"
      end

      referenced_paths.each do |path|
        next if path.match?(/[\[\]<>*{}]/)
        next if root.join(path).exist?

        errors << "#{display_path(document)}: responsible path does not exist: #{path}"
      end
    end

    def responsible_section(content, template)
      heading = case template
      when SHIPPED_TEMPLATE_ID
        "## 7. Responsible files and operations"
      when GAP_TEMPLATE_ID
        "## 5. Responsible documentation and history"
      else
        content[/^## \d+\. Responsible for Implementation Files$/]
      end
      return unless heading

      content[/^#{Regexp.escape(heading)}$.*?(?=^## \d+\.|\z)/m]
    end

    def audit_gap_claims(document, content, metadata)
      return unless metadata["status"] == NOT_IMPLEMENTED_STATUS

      runtime_paths = content.scan(RUNTIME_PATH_PATTERN).flatten.uniq
      return if runtime_paths.empty?

      errors << "#{display_path(document)}: NOT_IMPLEMENTED document claims runtime paths: #{runtime_paths.join(', ')}"
    end

    def audit_duplicate_titles(metadata_by_path)
      metadata_by_path.group_by { |_path, metadata| metadata["title"].to_s.strip }
        .each_value do |entries|
          title = entries.first.last["title"].to_s.strip
          next if title.empty? || entries.one?

          paths = entries.map { |path, _metadata| display_path(path) }
          errors << "duplicate feature title #{title.inspect}: #{paths.join(', ')}"
        end
    end

    def display_path(path)
      path.relative_path_from(root).to_s
    rescue ArgumentError
      path.to_s
    end
  end
end
