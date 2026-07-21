# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../../lib/feature_doc_audit"

RSpec.describe FeatureDocAudit::Auditor do
  subject(:audit) { described_class.new(root:, paths:, strict:).call }

  let(:temporary_directory) { Dir.mktmpdir("feature-doc-audit") }
  let(:root) { Pathname(temporary_directory) }
  let(:paths) { ["doc/features/example.md"] }
  let(:strict) { false }

  before do
    FileUtils.mkdir_p(root.join("doc/features"))
    FileUtils.mkdir_p(root.join("app/models"))
    root.join("app/models/example.rb").write("# frozen_string_literal: true\n")
    root.join("doc/features/FEATURE_TEMPLATE.md").write("[Feature Name]\n[Surface]\n")
  end

  after do
    FileUtils.remove_entry(temporary_directory)
  end

  it "accepts a canonical completed feature document" do
    write_document(canonical_document)

    expect(audit).to be_success
    expect(audit.errors).to be_empty
    expect(audit.warnings).to be_empty
  end

  it "reports missing canonical sections, unresolved placeholders, and missing responsible files" do
    write_document(
      canonical_document
        .sub("## 18. Version history\nContent.\n", "")
        .sub("Implemented content.", "[Surface]")
        .sub("app/models/example.rb", "app/models/missing.rb")
    )

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("numbered sections must match"))
    expect(audit.errors).to include(a_string_including("unresolved template placeholders"))
    expect(audit.errors).to include(a_string_including("responsible path does not exist"))
  end

  it "requires the canonical cross-feature relationship section" do
    write_document(
      canonical_document.sub(
        "### 1.1 Cross-feature relationships\n\nNo direct feature relationships.\n",
        ""
      )
    )

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("Cross-feature relationships section is required"))
  end

  it "requires cross-feature relationships to be reciprocal" do
    paths = ["doc/features/example.md", "doc/features/related.md"]
    first = canonical_document
      .sub("title: Example Feature", "title: First Feature")
      .sub(
        "No direct feature relationships.",
        "| `doc/features/related.md` | Runtime handoff | First owns entry; Related owns completion. |"
      )
    second = canonical_document.sub("title: Example Feature", "title: Related Feature")
    write_document(first)
    root.join("doc/features/related.md").write(second)

    result = described_class.new(root:, paths:).call

    expect(result).not_to be_success
    expect(result.errors).to include(a_string_including("relationship with doc/features/related.md is not reciprocal"))
  end

  it "rejects a cross-feature relationship to a missing handbook" do
    write_document(
      canonical_document.sub(
        "No direct feature relationships.",
        "| `doc/features/missing.md` | Runtime handoff | Explicit boundary. |"
      )
    )

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("related feature document does not exist"))
  end

  it "rejects a cross-feature relationship to the same handbook" do
    write_document(
      canonical_document.sub(
        "No direct feature relationships.",
        "| `doc/features/example.md` | Runtime handoff | Invalid self-boundary. |"
      )
    )

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("cross-feature relationship cannot reference itself"))
  end

  it "rejects unsupported status and malformed update metadata" do
    write_document(
      canonical_document
        .sub("status: Implemented MVP", "status: Planned")
        .sub("updated: 2026-07-21", "updated: soon")
    )

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("status must be one of"))
    expect(audit.errors).to include(a_string_including("updated must use YYYY-MM-DD"))
  end

  it "allows a pre-template handbook with required ownership/history sections and emits a migration warning" do
    write_document(legacy_document)

    expect(audit).to be_success
    expect(audit.warnings).to include(a_string_including("pre-template handbook"))
  end

  it "requires the canonical layout for a legacy handbook in strict mode" do
    write_document(legacy_document)
    strict = true
    result = described_class.new(root:, paths:, strict:).call

    expect(result).not_to be_success
    expect(result.errors).to include(a_string_including("numbered sections must match"))
  end

  context "when completed documents have duplicate titles" do
    let(:paths) { ["doc/features/example.md", "doc/features/duplicate.md"] }

    it "rejects duplicate canonical ownership" do
      write_document(canonical_document)
      root.join("doc/features/duplicate.md").write(canonical_document)

      expect(audit).not_to be_success
      expect(audit.errors).to include(a_string_including("duplicate feature title"))
    end
  end

  def write_document(content)
    root.join("doc/features/example.md").write(content)
  end

  def canonical_document
    <<~MARKDOWN
      # frozen_string_literal: true
      ---
      title: Example Feature
      description: Example implementation handbook.
      status: Implemented MVP
      updated: 2026-07-21
      owners: Example domain
      template: feature-v1
      ---

      # Example

      Implemented content.

      #{FeatureDocAudit::REQUIRED_SECTIONS.map { |heading| canonical_section(heading) }.join("\n")}
    MARKDOWN
  end

  def canonical_section(heading)
    body = if heading == FeatureDocAudit::REQUIRED_SECTIONS.first
      "\nContent.\n\n### 1.1 Cross-feature relationships\n\nNo direct feature relationships.\n"
    elsif heading.include?("Responsible for Implementation Files")
      "\n### Models and policies\n\n- `app/models/example.rb`\n"
    else
      "\nContent.\n"
    end

    "#{heading}#{body}"
  end

  def legacy_document
    <<~MARKDOWN
      # frozen_string_literal: true
      ---
      title: Example Feature
      description: Example implementation handbook.
      status: Implemented MVP
      updated: 2026-07-21
      owners: Example domain
      ---

      # Example

      ### 1.1 Cross-feature relationships

      No direct feature relationships.

      ## 1. Responsible for Implementation Files

      - `app/models/example.rb`

      ## 2. Version history

      Implemented.
    MARKDOWN
  end
end
