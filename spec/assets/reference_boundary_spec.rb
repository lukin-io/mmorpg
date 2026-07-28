# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Runtime reference boundary" do
  it "does not ship copied Neverlands runtime asset directories" do
    expect(Rails.root.join("app/assets/images/neverlands")).not_to exist
    expect(Rails.root.join("app/assets/images/world/neverlands_outskirts")).not_to exist
  end

  it "keeps known source-owned paths, branding, and project copy out of runtime presentation" do
    runtime_files = Rails.root.glob("app/views/**/*").select(&:file?) +
      Rails.root.glob("app/assets/stylesheets/**/*").select(&:file?)
    runtime_source = runtime_files.to_h { |path| [path.relative_path_from(Rails.root), path.read] }
    forbidden_fragments = [
      "Respectfully, Neverlands administration",
      "The profile keeps Neverlands",
      "assets/neverlands",
      "neverlands_outskirts",
      "image.neverlands.ru",
      'content: "NL"'
    ]

    aggregate_failures do
      forbidden_fragments.each do |fragment|
        offenders = runtime_source.filter_map { |path, source| path if source.include?(fragment) }

        expect(offenders).to be_empty, "#{fragment.inspect} found in #{offenders.join(', ')}"
      end
    end
  end

  it "uses styled ASCII text instead of copied bitmap-style controls" do
    control_files = %w[
      app/views/layouts/game.html.erb
      app/views/world/_city_view.html.erb
      app/views/shop/show.html.erb
      app/helpers/shop_helper.rb
      app/helpers/world_helper.rb
    ].index_with { |relative_path| Rails.root.join(relative_path).read }
    decorative_glyphs = %w[➜ → ↻ × ▲ ▼ ▶ ◀ ↗ ↖ ↘ ↙ ⚔ ⬟ ◇ ⚗ ▦ ✦]

    aggregate_failures do
      decorative_glyphs.each do |glyph|
        offenders = control_files.filter_map { |path, source| path if source.include?(glyph) }

        expect(offenders).to be_empty, "replace #{glyph.inspect} with a styled ASCII/text control in #{offenders.join(', ')}"
      end

      expect(control_files.fetch("app/views/layouts/game.html.erb")).to include(">X<", ">R<")
      expect(control_files.fetch("app/views/world/_city_view.html.erb")).to include("&gt;")
      expect(control_files.fetch("app/helpers/shop_helper.rb")).to include('"weapons" => "WP"')
    end
  end
end
