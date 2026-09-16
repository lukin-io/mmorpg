# frozen_string_literal: true

require "rails_helper"

RSpec.describe "shared/_nl_vitals_bar.html.erb", type: :view do
  let(:character) do
    create(:character,
      current_hp: 75,
      max_hp: 100,
      current_mp: 40,
      max_mp: 80,
      hp_regen_interval: 300,
      mp_regen_interval: 600)
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

    it "uses the authenticated server vitals endpoint" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-sync-url-value='/character_vitals']")
      expect(rendered).not_to include("regen-rate-value")
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

      expect(rendered.squish).to include("[<span class=\"nl-vitals-hp\"")
      expect(rendered).to have_css(".nl-vitals-hp", text: "75/100")
      expect(rendered).to have_css(".nl-vitals-mp", text: "40/80")
    end

    it "includes the HP and MP stimulus targets" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css("[data-nl-vitals-target='hpText']")
      expect(rendered).to have_css("[data-nl-vitals-target='mpText']")
    end
  end

  context "with equipment HP and MP bonuses" do
    let(:character) { create(:character, current_hp: 1500, max_hp: 1500, current_mp: 7, max_mp: 7) }
    let(:knife_template) { create(:item_template, :durable, stat_modifiers: {"hp" => 30, "mp" => 7}) }
    let!(:knife) do
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: knife_template,
        properties: {"current_durability" => 10})
    end

    it "uses each effective maximum once for text, data attributes and percentages without healing or base writes" do
      expect(character).to receive(:effective_max_hp).once.and_call_original
      expect(character).to receive(:effective_max_mp).once.and_call_original

      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css(".nl-vitals-hp", exact_text: "1500/1530")
      expect(rendered).to have_css(".nl-vitals-mp", exact_text: "7/14")
      expect(rendered).to have_css("[data-nl-vitals-max-hp-value='1530'][data-nl-vitals-max-mp-value='14']")
      expect(rendered).to have_css("[data-nl-vitals-current-hp-value='1500'][data-nl-vitals-current-mp-value='7']")
      expect(rendered).to have_css("[data-nl-vitals-target='hpFill'][style='width: 98%;']")
      expect(rendered).to have_css("[data-nl-vitals-target='mpFill'][style='width: 50%;']")
      expect(character.reload.attributes).to include("current_hp" => 1500, "max_hp" => 1500, "current_mp" => 7, "max_mp" => 7)
    end

    ["broken", "unequipped"].each do |state|
      it "returns to base maxima when the bonus item is #{state}" do
        if state == "broken"
          knife.update!(properties: {"current_durability" => 0})
        else
          knife.update!(equipped: false)
        end

        render partial: "shared/nl_vitals_bar", locals: {character: character}

        expect(rendered).to have_css(".nl-vitals-hp", exact_text: "1500/1500")
        expect(rendered).to have_css(".nl-vitals-mp", exact_text: "7/7")
        expect(rendered).to have_css("[data-nl-vitals-max-hp-value='1500'][data-nl-vitals-max-mp-value='7']")
        expect(rendered).to have_css(".nl-bar-fill[style='width: 100%;']", count: 2)
        expect(character.reload.attributes).to include("current_hp" => 1500, "max_hp" => 1500, "current_mp" => 7, "max_mp" => 7)
      end
    end
  end

  context "when effective maxima are zero" do
    let(:character) { create(:character, current_hp: 0, max_hp: 0, current_mp: 0, max_mp: 0) }

    it "renders zero percentages without division errors" do
      render partial: "shared/nl_vitals_bar", locals: {character: character}

      expect(rendered).to have_css(".nl-bar-fill[style='width: 0%;']", count: 2)
      expect(rendered).to have_css("[data-nl-vitals-max-hp-value='0'][data-nl-vitals-max-mp-value='0']")
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

  context "with HP values" do
    let(:hp_character) do
      # DB stores integers, so values are truncated
      create(:character, current_hp: 33, max_hp: 100, current_mp: 25, max_mp: 50)
    end

    it "displays HP value correctly" do
      render partial: "shared/nl_vitals_bar", locals: {character: hp_character}

      expect(rendered).to include("33/100")
    end

    it "displays MP value correctly" do
      render partial: "shared/nl_vitals_bar", locals: {character: hp_character}

      expect(rendered).to include("25/50")
    end
  end
end
