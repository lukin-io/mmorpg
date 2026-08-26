# frozen_string_literal: true

require "spec_helper"

RSpec.describe "CI workflow" do
  subject(:workflow) { File.read(File.expand_path("../../.github/workflows/ci.yml", __dir__)) }

  it "does not gate CI on mutable implementation receipts" do
    expect(workflow).not_to include("implementation-contract:")
    expect(workflow).not_to include("implementation-run-audit")
    expect(workflow).not_to include("fetch-depth: 0")
  end

  it "keeps documentation contracts in executable CI enforcement" do
    expect(workflow).to match(/^  documentation:$/)
    expect(workflow).to include("run: bin/verify docs")
  end

  it "preserves the parallel lint, test, system, and security jobs" do
    %w[security lint test system-test].each do |job|
      expect(workflow).to match(/^  #{Regexp.escape(job)}:$/)
    end
  end
end
