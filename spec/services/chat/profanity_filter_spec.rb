require "rails_helper"

RSpec.describe Chat::ProfanityFilter do
  subject(:filter) { described_class.new(dictionary: ["darn"]) }

  it "flags text containing banned words" do
    result = filter.call("darn this")

    expect(result.filtered_text).to eq("**** this")
    expect(result).to be_flagged
  end

  it "returns original text when no match" do
    result = filter.call("hello")

    expect(result.filtered_text).to eq("hello")
    expect(result).not_to be_flagged
  end
end
