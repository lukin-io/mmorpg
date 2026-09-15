# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena artwork delivery" do
  it "keeps the complete public log decoration at its documented aspect ratio" do
    path = Rails.root.join("app/assets/images/arena/fight_log_header.png")
    expect(File.binread(path, 24).byteslice(16, 8).unpack("N2")).to eq([1600, 640])
  end

  it "packages every original icon at four times its 16px square slot" do
    %w[rule timeout trauma].each do |name|
      path = Rails.root.join("app/assets/images/arena", "#{name}.png")
      expect(File.binread(path, 24).byteslice(16, 8).unpack("N2")).to eq([64, 64])
    end
  end

  it "packages the complete Training Dummy in the six-times 23:51 portrait frame" do
    path = Rails.root.join("app/assets/images/npc/scarecrow.png")
    expect(File.binread(path, 24).byteslice(16, 8).unpack("N2")).to eq([690, 1530])
  end
end
