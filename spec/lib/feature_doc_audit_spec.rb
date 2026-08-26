# frozen_string_literal: true

require "fileutils"
require "spec_helper"
require "tmpdir"
require_relative "../../lib/feature_doc_audit"

RSpec.describe FeatureDocAudit::Auditor do
  let(:root) { Pathname(Dir.mktmpdir("feature-doc-audit")) }

  before do
    write("doc/design/reference/example/README.md", "# Evidence\n")
    write("app/services/example_service.rb", "# frozen_string_literal: true\n")
    write("spec/services/example_service_spec.rb", "# frozen_string_literal: true\n")
  end

  after do
    FileUtils.remove_entry(root)
  end

  it "accepts the lean shipped handbook contract" do
    write("doc/features/example.md", shipped_document)

    result = audit

    expect(result).to be_success
    expect(result.documents_count).to eq(1)
  end

  it "accepts a documentation-only NOT_IMPLEMENTED gap" do
    write("doc/features/example.md", gap_document)

    expect(audit).to be_success
  end

  it "rejects runtime-path claims in a NOT_IMPLEMENTED gap" do
    write(
      "doc/features/example.md",
      gap_document.sub(
        "No adjacent runtime constitutes this feature.",
        "No adjacent runtime constitutes this feature. `app/services/example_service.rb` would own it."
      )
    )

    expect(audit.errors).to include(
      a_string_including("NOT_IMPLEMENTED document claims runtime paths")
    )
  end

  it "requires the concise canonical section order for new templates" do
    write(
      "doc/features/example.md",
      shipped_document.sub("## 4. Rails and Hotwire flow", "## 4. Custom workflow")
    )

    expect(audit.errors).to include(
      a_string_including("sections must match feature-v3 template exactly")
    )
  end

  it "reports unresolved placeholders and trailing whitespace" do
    write(
      "doc/features/example.md",
      shipped_document.sub("Current shipped behavior.", "<feature_name>. ").sub(
        "## 2. Player contract and non-goals",
        "## 2. Player contract and non-goals "
      )
    )

    result = audit

    expect(result.errors).to include(a_string_including("unresolved template placeholders"))
    expect(result.errors).to include(a_string_including("trailing whitespace"))
  end

  it "reports broken documentation and responsible-file paths" do
    write(
      "doc/features/example.md",
      shipped_document
        .sub("doc/design/reference/example/README.md", "doc/design/reference/missing/README.md")
        .sub("app/services/example_service.rb", "app/services/missing_service.rb")
    )

    result = audit

    expect(result.errors).to include(a_string_including("referenced document does not exist"))
    expect(result.errors).to include(a_string_including("responsible path does not exist"))
  end

  it "rejects duplicate canonical feature titles" do
    write("doc/features/one.md", shipped_document)
    write("doc/features/two.md", shipped_document)

    expect(audit.errors).to include(a_string_including("duplicate feature title"))
  end

  it "keeps legacy handbooks compatible without requiring migration" do
    write("doc/features/example.md", legacy_document)

    result = audit

    expect(result).to be_success
    expect(result.warnings).to be_empty
  end

  it "can reject legacy handbooks in an explicitly strict migration check" do
    write("doc/features/example.md", legacy_document)

    result = described_class.new(root:, strict: true).call

    expect(result.errors).to include(a_string_including("legacy feature-v1 handbook"))
  end

  it "requires NOT_IMPLEMENTED status and gap template to agree" do
    write(
      "doc/features/example.md",
      gap_document.sub("status: NOT_IMPLEMENTED", "status: Fully Implemented")
    )

    expect(audit.errors).to include(
      a_string_including("feature-gap-v2 requires NOT_IMPLEMENTED status")
    )
  end

  it "reports an explicitly requested missing document" do
    result = described_class.new(root:, paths: ["doc/features/missing.md"]).call

    expect(result.errors).to include(
      a_string_including("doc/features/missing.md: document does not exist")
    )
  end

  def audit
    described_class.new(root:).call
  end

  def write(path, content)
    destination = root.join(path)
    FileUtils.mkdir_p(destination.dirname)
    destination.write(content)
  end

  def shipped_document
    <<~MARKDOWN
      # frozen_string_literal: true
      ---
      title: Example Feature
      description: Verified example behavior.
      status: Fully Implemented
      updated: 2026-08-26
      owners: Example domain
      template: feature-v3
      ---

      # Example

      ## 1. Authority and scope

      Evidence: `doc/design/reference/example/README.md`.

      ## 2. Player contract and non-goals

      Current shipped behavior.

      ## 3. Authoritative state and content

      The server owns state.

      ## 4. Rails and Hotwire flow

      Rails renders HTML.

      ## 5. Security, concurrency, and failure behavior

      Failed mutations preserve state.

      ## 6. Acceptance and tests

      Covered by focused specs.

      ## 7. Responsible files and operations

      - `app/services/example_service.rb`
      - `spec/services/example_service_spec.rb`

      ## 8. Gaps and version history

      None.
    MARKDOWN
  end

  def gap_document
    <<~MARKDOWN
      # frozen_string_literal: true
      ---
      title: Example Feature
      description: NOT_IMPLEMENTED example boundary.
      status: NOT_IMPLEMENTED
      updated: 2026-08-26
      owners: Example domain
      template: feature-gap-v2
      ---

      # Example

      ## 1. Evidence and design

      Evidence: `doc/design/reference/example/README.md`.

      ## 2. Missing runtime contract

      `NOT_IMPLEMENTED`: no route, state, mutation, persistence, UI owner, or spec exists.

      ## 3. Existing related handoffs

      No adjacent runtime constitutes this feature.

      ## 4. Prerequisites for implementation

      Capture Neverlands evidence before implementation.

      ## 5. Responsible documentation and history

      - `doc/features/example.md`
      - `doc/design/reference/example/README.md`
    MARKDOWN
  end

  def legacy_document
    <<~MARKDOWN
      # frozen_string_literal: true
      ---
      title: Example Feature
      description: Legacy verified behavior.
      status: Fully Implemented
      updated: 2026-08-26
      owners: Example domain
      template: feature-v1
      ---

      # Example

      ## 1. Summary

      Existing behavior.

      ## 2. Responsible for Implementation Files

      - `app/services/example_service.rb`

      ## 3. Version history

      Existing history.
    MARKDOWN
  end
end
