# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manage::PaginatedRelation do
  before { create_list(:zone, 3) }

  it "returns a bounded page and navigation metadata" do
    result = described_class.new(relation: Zone.order(:id), page: 2, per_page: 2).call

    expect(result.records.size).to eq(1)
    expect(result).to have_attributes(page: 2, per_page: 2, total_count: 3, total_pages: 2, previous_page: 1, next_page: nil)
  end

  it "normalizes null, negative, and oversized browser values" do
    default_page = described_class.new(relation: Zone.all, page: nil).call
    clamped = described_class.new(relation: Zone.all, page: -4, per_page: 10_000).call

    expect(default_page.page).to eq(1)
    expect(clamped).to have_attributes(page: 1, per_page: described_class::MAX_PER_PAGE)
  end
end
