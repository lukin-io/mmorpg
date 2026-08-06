# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../../lib/documentation_architecture_audit"

RSpec.describe DocumentationArchitectureAudit::Auditor do
  subject(:audit) do
    described_class.new(
      root:,
      domains: ["world"],
      baseline_paths: ["doc/README.md"],
      implementation_placeholders: ["doc/features/missing.md"],
      evidence_placeholders: [evidence_path],
      compatibility_aliases: {alias_path => observation_path}
    ).call
  end

  let(:temporary_directory) { Dir.mktmpdir("documentation-architecture-audit") }
  let(:root) { Pathname(temporary_directory) }
  let(:evidence_path) { "doc/design/reference/world/observations/evidence_needed.md" }
  let(:observation_path) { "doc/design/reference/world/observations/current.md" }
  let(:alias_path) { "doc/design/reference/legacy_world.md" }

  before do
    write_required_entry_points
    write("doc/README.md", "# Portal\n")
    write(
      "doc/domains/world.md",
      <<~MARKDOWN
        # World
        ## Documentation chain
        `doc/design/reference/world/README.md`
        `doc/design/launch_mvp_plan.md`
        `WORLD-001`
        ## Current RPG status
        Current.
        ## Important responsible implementation files
        `app/models/example.rb`
      MARKDOWN
    )
    write("app/models/example.rb", "# frozen_string_literal: true\n")
    write("doc/design/launch_mvp_plan.md", "# Plan\n`WORLD-001`\n")
    write("doc/design/reference/world/README.md", source_document("world"))
    write(observation_path, source_document("world"))
    write(evidence_path, source_document("world", evidence: true))
    write(alias_path, "Canonical: `#{observation_path}`\n")
    write(
      "doc/features/missing.md",
      "status: NOT_IMPLEMENTED\n## 16. Responsible for Implementation Files\n"
    )
    write(
      "doc/DOCUMENTATION_MIGRATION_MANIFEST.md",
      "`doc/README.md`\n1 of 1 documents have an explicit disposition\n"
    )
  end

  after do
    FileUtils.remove_entry(temporary_directory)
  end

  it "accepts a complete domain evidence-to-implementation registry" do
    expect(audit).to be_success
    expect(audit.errors).to be_empty
  end

  it "reports a missing source summary" do
    FileUtils.rm(root.join("doc/design/reference/world/README.md"))

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("document does not exist"))
  end

  it "reports missing local implementation linkage" do
    write("doc/design/reference/world/README.md", "- Domain: world\n")

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("## Local Implementation Linkage"))
  end

  it "reports a baseline document omitted from the manifest" do
    write("doc/DOCUMENTATION_MIGRATION_MANIFEST.md", "1 of 1 documents have an explicit disposition\n")

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("doc/README.md"))
  end

  it "reports a missing repository path referenced by an owned document" do
    write("doc/domains/world.md", root.join("doc/domains/world.md").read.sub("app/models/example.rb", "app/models/missing.rb"))

    expect(audit).not_to be_success
    expect(audit.errors).to include(a_string_including("referenced repository path does not exist"))
  end

  def write_required_entry_points
    %w[
      doc/DOCUMENTATION.md
      doc/templates/README.md
      doc/templates/DOMAIN_INDEX_TEMPLATE.md
      doc/templates/NEVERLANDS_SOURCE_SUMMARY_TEMPLATE.md
      doc/templates/NEVERLANDS_OBSERVATION_TEMPLATE.md
      doc/templates/DESIGN_PLACEHOLDER_TEMPLATE.md
      doc/features/NOT_IMPLEMENTED_TEMPLATE.md
    ].each { |path| write(path, "# Required\n") }
    write("doc/domains/README.md", "`doc/domains/world.md`\n")
    write(
      "doc/design/reference/README.md",
      "`doc/design/reference/world/README.md`\n"
    )
  end

  def source_document(domain, evidence: false)
    <<~MARKDOWN
      - Domain: #{domain}
      #{"- Evidence status: EVIDENCE_NEEDED" if evidence}
      ## Local Implementation Linkage
      ### Responsible implementation files
      `app/models/example.rb`
      Local implementation linkage is context, not Neverlands evidence.
    MARKDOWN
  end

  def write(path, content)
    document = root.join(path)
    FileUtils.mkdir_p(document.dirname)
    document.write(content)
  end
end
