# frozen_string_literal: true

require "fileutils"
require "spec_helper"
require "tmpdir"
require_relative "../../lib/documentation_architecture_audit"

RSpec.describe DocumentationArchitectureAudit::Auditor do
  let(:root) { Pathname(Dir.mktmpdir("documentation-architecture-audit")) }

  before do
    DocumentationArchitectureAudit::REQUIRED_ENTRY_POINTS.each do |path|
      write(path, "# #{File.basename(path)}\n")
    end

    write("doc/domains/README.md", "- `doc/domains/world.md`\n")
    write(
      "doc/design/reference/README.md",
      "- `doc/design/reference/world/README.md`\n"
    )
    write(
      "doc/domains/world.md",
      <<~MARKDOWN
        # World

        Source: `doc/design/reference/world/README.md`
        Runtime owner: `doc/features/world.md`
      MARKDOWN
    )
    write("doc/design/reference/world/README.md", "Domain: world\n")
    write("doc/features/world.md", "# World feature\n")
    FileUtils.mkdir_p(root.join("doc/design/reference/world/observations"))
  end

  after do
    FileUtils.remove_entry(root)
  end

  it "accepts domain ownership and resolvable canonical paths" do
    expect(audit).to be_success
  end

  it "does not require README wording, a fixed baseline manifest, or workflow receipts" do
    expect(root.join("README.md")).not_to exist
    expect(root.join("doc/DOCUMENTATION_MIGRATION_MANIFEST.md")).not_to exist

    expect(audit).to be_success
  end

  it "requires each domain registry owner exactly once" do
    write("doc/domains/README.md", "- `doc/domains/world.md`\n- `doc/domains/world.md`\n")

    expect(audit.errors).to include(
      "doc/domains/README.md: expected exactly one reference to doc/domains/world.md, found 2"
    )
  end

  it "requires the domain page to point to evidence and a feature owner" do
    write("doc/domains/world.md", "# World\n")

    result = audit

    expect(result.errors).to include(
      a_string_including("required content missing: doc/design/reference/world/README.md")
    )
    expect(result.errors).to include(
      a_string_including("at least one feature-handbook owner is required")
    )
  end

  it "allows a source summary to index evidence without a local observations directory" do
    write(
      "doc/design/reference/world/README.md",
      "Domain: world\nEvidence: `doc/design/reference/shared_observation.md`\n"
    )
    write("doc/design/reference/shared_observation.md", "# Shared observation\n")
    FileUtils.remove_dir(root.join("doc/design/reference/world/observations"))

    expect(audit).to be_success
  end

  it "validates EVIDENCE_NEEDED placeholder markers" do
    write(
      "doc/design/reference/world/observations/evidence_needed_flow.md",
      "# Missing evidence\n"
    )

    expect(audit.errors).to include(
      a_string_including("required content missing: Evidence status: EVIDENCE_NEEDED")
    )
  end

  it "reports broken repository paths in audited documents" do
    write(
      "doc/domains/world.md",
      <<~MARKDOWN
        # World

        Source: `doc/design/reference/world/README.md`
        Runtime owner: `doc/features/world.md`
        Missing owner: `app/services/missing.rb`
      MARKDOWN
    )

    expect(audit.errors).to include(
      a_string_including("referenced repository path does not exist: app/services/missing.rb")
    )
  end

  it "reports broken relative Markdown document links" do
    write(
      "doc/design/reference/world/README.md",
      "Domain: world\n[Missing](observations/missing.md)\n"
    )

    expect(audit.errors).to include(
      a_string_including("referenced Markdown document does not exist")
    )
  end

  it "validates compatibility aliases without copying source evidence" do
    write("doc/alias.md", "Canonical: `doc/canonical.md`\n")
    write("doc/canonical.md", "# Canonical\n")

    result = audit(compatibility_aliases: {"doc/alias.md" => "doc/canonical.md"})

    expect(result).to be_success
  end

  it "reports missing required entry points" do
    FileUtils.rm(root.join("doc/templates/README.md"))

    expect(audit.errors).to include("doc/templates/README.md: document does not exist")
  end

  def audit(**options)
    described_class.new(
      root:,
      domains: ["world"],
      compatibility_aliases: {},
      **options
    ).call
  end

  def write(path, content)
    destination = root.join(path)
    FileUtils.mkdir_p(destination.dirname)
    destination.write(content)
  end
end
