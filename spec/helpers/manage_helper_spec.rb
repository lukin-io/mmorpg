# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManageHelper, type: :helper do
  describe "#management_enum_label" do
    it "localizes known enum values" do
      I18n.with_locale(:ru) do
        expect(helper.management_enum_label(:hotspot_type, "building")).to eq(
          I18n.t("manage.views.enums.hotspot_type.building")
        )
      end
    end

    it "returns an em dash for blank values" do
      expect(helper.management_enum_label(:npc_role, nil)).to eq("—")
    end
  end

  describe "#management_enum_options" do
    it "pairs localized labels with raw values" do
      options = helper.management_enum_options(:action_type, %w[enter_zone])
      expect(options).to eq([[helper.management_enum_label(:action_type, "enter_zone"), "enter_zone"]])
    end
  end

  describe "#management_audit_action_label" do
    it "localizes audit actions" do
      I18n.with_locale(:ru) do
        expect(helper.management_audit_action_label("create")).to eq(
          I18n.t("manage.views.audit_actions.create")
        )
      end
    end
  end
end
