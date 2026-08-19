# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManagePolicy do
  subject(:policy) { described_class.new(user, :manage) }

  context "with an administrator" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to be_access }
  end

  context "with a moderator" do
    let(:user) { create(:user, :moderator) }

    it { is_expected.not_to be_access }
  end

  context "with an ordinary player" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_access }
  end

  context "without a user" do
    let(:user) { nil }

    it { is_expected.not_to be_access }
  end
end
