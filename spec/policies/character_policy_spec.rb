# frozen_string_literal: true

require "rails_helper"

RSpec.describe CharacterPolicy do
  subject(:policy) { described_class.new(user, character) }

  let(:owner) { create(:user) }
  let(:character) { create(:character, user: owner) }

  describe "#manage_progression?" do
    context "when the user owns the character" do
      let(:user) { owner }

      it { is_expected.to be_manage_progression }
    end

    context "when the user owns a different character" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_manage_progression }
    end

    context "when the user is nil" do
      let(:user) { nil }

      it { is_expected.not_to be_manage_progression }
    end
  end
end
