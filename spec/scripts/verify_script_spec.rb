# frozen_string_literal: true

require "spec_helper"

RSpec.describe "bin/verify" do
  subject(:script) { File.read(File.expand_path("../../bin/verify", __dir__)) }

  it "keeps verification read-only" do
    expect(script).not_to include("standardrb --fix")
    expect(script).not_to match(/rubocop\s+-a(?:\s|$)/)
  end

  it "matches the RSpec CI split" do
    expect(script).to include('bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"')
    expect(script).to include("bundle exec rspec spec/system")
  end

  it "includes security and feature-document checks in the full workflow" do
    expect(script).to include("bundle exec brakeman --quiet --no-pager")
    expect(script).not_to include("--exit-on-warn")
    expect(script).to include("bin/bundler-audit check --update")
    expect(script).to include("bin/importmap audit")
    expect(script).to include("bin/feature-doc-audit")
  end
end
