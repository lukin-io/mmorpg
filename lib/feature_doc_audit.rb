# frozen_string_literal: true

require "pathname"

# Validates completed feature handbooks against the canonical documentation
# contract without loading Rails or mutating repository files.
module FeatureDocAudit
  TEMPLATE_ID = "feature-v1"
  ALLOWED_STATUSES = ["Implemented MVP", "Partially Implemented"].freeze
  REQUIRED_SECTIONS = [
    "## 1. Design authority and related documents",
    "## 2. Feature summary",
    "## 3. MVP goals and non-goals",
    "## 4. Player experience",
    "## 5. Feature topology and authored content",
    "## 6. Feature surfaces and contained behavior",
    "## 7. Authoritative data and presentation model",
    "## 8. Runtime architecture",
    "## 9. HTTP and Turbo contract",
    "## 10. Client-side and CSS ownership",
    "## 11. Persistence and login resume",
    "## 12. Authorization, trust boundaries, and concurrency",
    "## 13. Failure and boundary behavior",
    "## 14. Acceptance criteria",
    "## 15. Test strategy and required coverage",
    "## 16. Responsible for Implementation Files",
    "## 17. Safe extension checklist",
    "## 18. Version history"
  ].freeze
  COMPLETED_DOC_EXCLUSIONS = %w[FEATURE_TEMPLATE.md README.md].freeze
  REPOSITORY_PATH_PATTERN = /`((?:app|bin|config|db|doc|lib|spec)\/[^`\n]+)`/
  CROSS_FEATURE_HEADING = "### 1.1 Cross-feature relationships"
  FEATURE_DOC_PATH_PATTERN = /`(doc\/features\/[a-z0-9_]+\.md)`/

  Result = Struct.new(:documents_count, :errors, :warnings, keyword_init: true) do
    def success?
      errors.empty?
    end
  end

  # Audits explicit feature documents or every completed handbook under
  # doc/features when no paths are provided.
  class Auditor
    # @param root [String, Pathname] repository root
    # @param paths [Array<String, Pathname>] explicit documents to audit
    # @param strict [Boolean] require the canonical layout for pre-template docs
    def initialize(root:, paths: [], strict: false)
      @root = Pathname(root).expand_path
      @paths = Array(paths)
      @strict = strict
      @errors = []
      @warnings = []
    end

    # Performs a read-only audit.
    #
    # @return [FeatureDocAudit::Result]
    def call
      documents = documents_to_audit
      metadata_by_path = documents.to_h do |document|
        content = read_document(document)
        metadata = audit_document(document, content)
        [document, metadata]
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
          COMPLETED_DOC_EXCLUSIONS.include?(document.basename.to_s)
        end
      else
        paths.map { |document| resolve_path(document) }
      end

      documents.sort_by(&:to_s)
    end

    def resolve_path(document)
      candidate = Pathname(document)
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

      if strict || metadata["template"] == TEMPLATE_ID
        audit_canonical_layout(document, content)
        audit_placeholders(document, content)
      else
        audit_legacy_layout(document, content)
      end

      audit_cross_feature_relationships(document, content)
      audit_responsible_files(document, content)
      metadata
    end

    def parse_frontmatter(document, content)
      lines = content.lines
      errors << "#{display_path(document)}: first line must be # frozen_string_literal: true" unless lines.first&.strip == "# frozen_string_literal: true"
      errors << "#{display_path(document)}: YAML metadata must begin on line 2" unless lines[1]&.strip == "---"

      closing_index = lines.each_index.drop(2).find { |index| lines[index].strip == "---" }
      unless closing_index
        errors << "#{display_path(document)}: YAML metadata closing delimiter is missing"
        return {}
      end

      lines[2...closing_index].to_h do |line|
        key, value = line.split(":", 2)
        [key.to_s.strip, unquote(value.to_s.strip)]
      end
    end

    def unquote(value)
      return value[1...-1] if value.length >= 2 && ["\"", "'"].include?(value[0]) && value[-1] == value[0]

      value
    end

    def audit_metadata(document, metadata)
      %w[title description status updated owners].each do |key|
        errors << "#{display_path(document)}: metadata #{key} is required" if metadata[key].to_s.empty?
      end

      unless ALLOWED_STATUSES.include?(metadata["status"])
        errors << "#{display_path(document)}: status must be one of #{ALLOWED_STATUSES.join(', ')}"
      end

      unless metadata["updated"].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        errors << "#{display_path(document)}: updated must use YYYY-MM-DD"
      end

      template_id = metadata["template"]
      return if template_id.nil? || template_id == TEMPLATE_ID

      errors << "#{display_path(document)}: unsupported template #{template_id.inspect}"
    end

    def audit_whitespace(document, content)
      content.lines.each_with_index do |line, index|
        errors << "#{display_path(document)}:#{index + 1}: trailing whitespace" if line.match?(/[ \t]+$/)
      end
    end

    def audit_canonical_layout(document, content)
      actual = content.lines.grep(/^## \d+\./).map(&:strip)
      return if actual == REQUIRED_SECTIONS

      errors << "#{display_path(document)}: numbered sections must match FEATURE_TEMPLATE.md exactly"
    end

    def audit_placeholders(document, content)
      unresolved = placeholder_tokens.select { |placeholder| content.include?(placeholder) }
      unresolved << "Template instruction" if content.include?("Template instruction")
      unresolved << "YYYY-MM-DD" if content.include?("YYYY-MM-DD")
      unresolved << "<feature_name>" if content.include?("<feature_name>")
      return if unresolved.empty?

      errors << "#{display_path(document)}: unresolved template placeholders: #{unresolved.uniq.first(5).join(', ')}"
    end

    def placeholder_tokens
      @placeholder_tokens ||= begin
        template = root.join("doc/features/FEATURE_TEMPLATE.md")
        if template.file?
          template.read.scan(/\[[^\]\n]+\]/).select { |token| token.match?(/[A-Za-z]/) }.uniq
        else
          []
        end
      end
    end

    def audit_legacy_layout(document, content)
      unless content.match?(/^## \d+\. Responsible for Implementation Files$/)
        errors << "#{display_path(document)}: Responsible for Implementation Files section is required"
      end
      unless content.match?(/^## \d+\. Version history$/i)
        errors << "#{display_path(document)}: Version history section is required"
      end

      warnings << "#{display_path(document)}: pre-template handbook; migrate to #{TEMPLATE_ID} on its next material update"
    end

    def audit_responsible_files(document, content)
      responsible_section = content[/^## \d+\. Responsible for Implementation Files$.*?(?=^## \d+\.|\z)/m]
      return unless responsible_section

      referenced_paths = responsible_section.scan(REPOSITORY_PATH_PATTERN).flatten
      errors << "#{display_path(document)}: responsible-file inventory is empty" if referenced_paths.empty?

      referenced_paths.each do |referenced_path|
        next if referenced_path.match?(/[\[\]<>*{}]/)
        next if root.join(referenced_path).exist?

        errors << "#{display_path(document)}: responsible path does not exist: #{referenced_path}"
      end
    end

    def audit_cross_feature_relationships(document, content)
      section = content[/^#{Regexp.escape(CROSS_FEATURE_HEADING)}$.*?(?=^## |\z)/m]
      unless section
        errors << "#{display_path(document)}: #{CROSS_FEATURE_HEADING} section is required"
        return
      end

      section.scan(FEATURE_DOC_PATH_PATTERN).flatten.uniq.each do |related_path|
        if related_path == display_path(document)
          errors << "#{display_path(document)}: cross-feature relationship cannot reference itself"
          next
        end

        related_document = root.join(related_path)
        unless related_document.file?
          errors << "#{display_path(document)}: related feature document does not exist: #{related_path}"
          next
        end

        related_content = related_document.read
        related_section = related_content[/^#{Regexp.escape(CROSS_FEATURE_HEADING)}$.*?(?=^## |\z)/m]
        backlink = "`#{display_path(document)}`"
        next if related_section&.include?(backlink)

        errors << "#{display_path(document)}: relationship with #{related_path} is not reciprocal"
      end
    end

    def audit_duplicate_titles(metadata_by_path)
      metadata_by_path.group_by { |_document, metadata| metadata["title"] }.each do |title, entries|
        next if title.to_s.empty? || entries.one?

        paths = entries.map { |document, _metadata| display_path(document) }.join(", ")
        errors << "duplicate feature title #{title.inspect}: #{paths}"
      end
    end

    def display_path(document)
      document.relative_path_from(root).to_s
    rescue ArgumentError
      document.to_s
    end
  end
end
