# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Original World walking artwork" do
  %w[north northeast east southeast south southwest west northwest].each do |direction|
    context "facing #{direction}" do
      it "ships a small transparent eight-frame GIF with a repeating 800ms cycle" do
        path = Rails.root.join("app/assets/images/world/traveller-walking-#{direction}.gif")
        bytes = path.binread

        expect(bytes.byteslice(0, 6)).to eq("GIF89a")
        expect(bytes.byteslice(6, 4).unpack("v2")).to eq([96, 96])
        expect(bytes).to include("NETSCAPE2.0\x03\x01\x00\x00\x00".b)
        expect(bytes.bytesize).to be < 40_000

        # Each packaged frame has a GIF graphic-control extension. Its packed
        # flags retain transparency and background disposal between walk poses.
        controls = bytes.scan(/\x21\xF9\x04(.)(..).\x00/mn)
        expect(controls.length).to eq(8)
        expect(controls.map { |flags, _delay| flags.ord & 1 }).to all(eq(1))
        expect(controls.map { |flags, _delay| (flags.ord >> 2) & 7 }).to all(eq(2))
        expect(controls.map { |_flags, delay| delay.unpack1("v") }).to eq([10] * 8)
      end

      it "ships an equally sized RGBA still for reduced-motion clients" do
        path = Rails.root.join("app/assets/images/world/traveller-walking-#{direction}-still.png")
        header = File.binread(path, 26)

        expect(header.byteslice(0, 8)).to eq("\x89PNG\r\n\x1A\n".b)
        expect(header.byteslice(12, 4)).to eq("IHDR")
        expect(header.byteslice(16, 8).unpack("N2")).to eq([96, 96])
        expect(header.getbyte(25)).to eq(6)
      end
    end
  end
end
