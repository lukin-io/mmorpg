# frozen_string_literal: true

require "rails_helper"

RSpec.describe "shared/_nl_vitals_bar.html.erb", type: :view do
  let(:character) do
    create(:character).tap do |c|
      allow(c).to receive(:current_hp).and_return(75)
      allow(c).to receive(:max_hp).and_return(100)
      allow(c).to receive(:current_mp).and_return(40)
      allow(c).to receive(:max_mp).and_return(80)
      allow(c).to receive(:hp_regen_interval_seconds).and_return(1500)
      allow(c).to receive(:mp_regen_interval_seconds).and_return(9000)
    end
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:current_character).and_return(character)
    end
  end

  describe "vitals container" do
    it "renders the inline vitals container" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css(".nl-vitals-inline")
    end

    it "includes stimulus controller data attributes" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-controller='nl-vitals']")
    end
  end

  describe "HP/MP data values" do
    it "sets current HP value" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-current-hp-value='75']")
    end

    it "sets max HP value" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-max-hp-value='100']")
    end

    it "sets current MP value" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-current-mp-value='40']")
    end

    it "sets max MP value" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-max-mp-value='80']")
    end

    it "includes regen rate data attributes" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-hp-regen-rate-value='1500']")
      expect(rendered).to have_css("[data-nl-vitals-mp-regen-rate-value='9000']")
    end
  end

  describe "HP bar (inline format)" do
    it "renders HP bar container" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css(".nl-hp-bar-inline")
    end

    it "renders HP bar fill element" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css(".nl-hp-bar-inline .nl-bar-fill")
    end

    it "includes HP bar stimulus target" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-target='hpBar']")
      expect(rendered).to have_css("[data-nl-vitals-target='hpFill']")
    end

    it "sets HP fill width as percentage (75%)" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      # 75/100 = 75%
      expect(rendered).to include("width: 75%")
    end
  end

  describe "vitals text display" do
    it "renders vitals text element" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css(".nl-vitals-text")
    end

    it "displays values in format [HP/MaxHP | MP/MaxMP]" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      # Format: [75/100 | 40/80]
      expect(rendered).to include("[75/100")
      expect(rendered).to include("40/80]")
    end

    it "includes text stimulus target" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-target='text']")
    end
  end

  context "when character has full HP" do
    let(:full_hp_character) do
      create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)
    end

    it "shows 100% HP fill" do
      render partial: "shared/nl_vitals_bar", locals: {character: full_hp_character}

      expect(rendered).to include("width: 100%")
    end

    it "displays full HP values" do
      render partial: "shared/nl_vitals_bar", locals: {character: full_hp_character}

      expect(rendered).to include("100/100")
    end
  end

  context "when character has zero HP" do
    let(:dead_character) do
      create(:character, current_hp: 0, max_hp: 100, current_mp: 0, max_mp: 50)
    end

    it "shows 0% HP fill" do
      render partial: "shared/nl_vitals_bar", locals: {character: dead_character}

      expect(rendered).to include("width: 0%")
    end

    it "displays zero HP values" do
      render partial: "shared/nl_vitals_bar", locals: {character: dead_character}

      expect(rendered).to include("0/100")
    end
  end

  context "when character has low HP (under 25%)" do
    let(:low_hp_character) do
      create(:character, current_hp: 20, max_hp: 100, current_mp: 10, max_mp: 50)
    end

    it "shows 20% HP fill" do
      render partial: "shared/nl_vitals_bar", locals: {character: low_hp_character}

      expect(rendered).to include("width: 20%")
    end
  end

  context "with decimal HP values" do
    let(:decimal_hp_character) do
      create(:character, current_hp: 33.7, max_hp: 100, current_mp: 25.5, max_mp: 50)
    end

    it "rounds HP display value" do
      render partial: "shared/nl_vitals_bar", locals: {character: decimal_hp_character}

      expect(rendered).to include("34/100") # 33.7 rounds to 34
    end

    it "rounds MP display value" do
      render partial: "shared/nl_vitals_bar", locals: {character: decimal_hp_character}

      expect(rendered).to include("26/50") # 25.5 rounds to 26
    end
  end
end
