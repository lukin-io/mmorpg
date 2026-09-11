# frozen_string_literal: true

require "rails_helper"
require_relative "../support/walker_gif_frames"

RSpec.describe "Original World walking artwork" do
  let(:registration) { JSON.parse(Rails.root.join("doc/artwork/traveller-walk-registration.json").read) }

  def geometry(frame)
    points = frame.alpha.each_index.filter_map { |index| [index % frame.width, index / frame.width] if frame.alpha[index] }
    top, bottom = points.map(&:last).minmax
    height = bottom - top + 1
    centroid = lambda do |from, to|
      band = points.select { |_x, y| y >= top + height * from && y < top + height * to }
      [0, 1].map { |axis| band.sum { |point| point[axis] }.fdiv(band.length) }
    end

    {head: centroid.call(0, 0.18), torso: centroid.call(0.2, 0.55), feet: bottom, top: top}
  end

  def span(values)
    values.max - values.min
  end

  %w[north northeast east southeast south southwest west northwest].each do |direction|
    context "facing #{direction}" do
      let(:record) { registration.fetch("directions").fetch(direction) }
      let(:path) { Rails.root.join("app/assets/images/world/traveller-walking-#{direction}.gif") }

      it "ships a transparent full-frame GIF with its recorded repeating cycle" do
        bytes = path.binread

        expect(bytes.byteslice(0, 6)).to eq("GIF89a")
        expect(bytes.byteslice(6, 4).unpack("v2")).to eq([128, 128])
        expect(bytes).to include("NETSCAPE2.0\x03\x01\x00\x00\x00".b)
        expect(bytes.bytesize).to be < 40_000
        expect(record.fetch("frame_count")).to be_in([4, 8])
        expect(record.fetch("delay_centiseconds")).to be_between(10, 14)
        expect(Digest::SHA256.hexdigest(bytes)).to eq(record.fetch("gif_sha256"))

        # Each packaged frame has a GIF graphic-control extension. Its packed
        # flags retain transparency and background disposal between walk poses.
        controls = bytes.scan(/\x21\xF9\x04(.)(..).\x00/mn)
        expect(controls.length).to eq(record.fetch("frame_count"))
        expect(controls.map { |flags, _delay| flags.ord & 1 }).to all(eq(1))
        expect(controls.map { |flags, _delay| (flags.ord >> 2) & 7 }).to all(eq(2))
        expect(controls.map { |_flags, delay| delay.unpack1("v") }).to eq([record.fetch("delay_centiseconds")] * controls.length)
      end

      it "keeps the decoded head steady and the complete figure inside its canvas throughout the loop" do
        frames = WalkerGifFrames.read(path)
        positions = frames.map { |frame| geometry(frame) }

        expect(frames.length).to eq(record.fetch("frame_count"))
        expect(frames.map { |frame| [frame.width, frame.height] }).to all(eq([128, 128]))
        # At 64 CSS px these limits permit at most 1px head drift and 2.25px of
        # upper-body silhouette movement from arms/cloak. A lifted/bent leg can
        # change the silhouette's bottom without moving the body's anchor.
        expect(span(positions.map { |position| position.fetch(:head)[0] })).to be <= 2
        expect(span(positions.map { |position| position.fetch(:head)[1] })).to be <= 2
        expect(span(positions.map { |position| position.fetch(:torso)[0] })).to be <= 4.5
        expect(positions.map { |position| position.fetch(:top) }).to all(be >= 2)
        expect(positions.map { |position| position.fetch(:feet) }).to all(be <= 125)
        expect(frames.map(&:alpha).uniq.length).to eq(frames.length)
      end

      it "ships an equally sized RGBA still for reduced-motion clients" do
        path = Rails.root.join("app/assets/images/world/traveller-walking-#{direction}-still.png")
        header = File.binread(path, 26)

        expect(header.byteslice(0, 8)).to eq("\x89PNG\r\n\x1A\n".b)
        expect(header.byteslice(12, 4)).to eq("IHDR")
        expect(header.byteslice(16, 8).unpack("N2")).to eq([128, 128])
        expect(header.getbyte(25)).to eq(6)
        expect(Digest::SHA256.file(path).hexdigest).to eq(record.fetch("still_sha256"))
      end
    end
  end
end
