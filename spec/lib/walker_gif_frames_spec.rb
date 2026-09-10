# frozen_string_literal: true

require "spec_helper"
require_relative "../support/walker_gif_frames"

RSpec.describe WalkerGifFrames do
  # LZW codes clear,0,1,1,0,end at widths 3,3,3,3,4,4 encode this
  # known 2x2 mask. Keeping literal bytes makes this independent of the decoder.
  def sample(local: false, left: 0, flags: 0, transparent: true, width: 2, height: 2,
    blocks: "\x03\x44\x02\x05\x00".b)
    palette = "\0\0\0\xff\xff\xff".b
    "GIF89a".b + [width, height, local ? 0 : 0x80, 0, 0].pack("v2C3") +
      (local ? "".b : palette) +
      [0x21, 0xf9, 4, transparent ? 9 : 8, 10, 0, 0, 0].pack("C*") +
      [0x2c].pack("C") + [left, 0, width, height, flags | (local ? 0x80 : 0)].pack("v4C") +
      (local ? palette : "".b) + "\x02".b + blocks + "\x3b".b
  end

  it "decodes exact row-major transparency through an LZW code-width change" do
    expect(described_class.new(sample).frames).to eq([
      described_class::Frame.new(width: 2, height: 2, alpha: [false, true, true, false])
    ])
  end

  it "uses a local palette and joins split image-data sub-blocks" do
    bytes = sample(local: true, blocks: "\x01\x44\x01\x02\x01\x05\x00".b)

    expect(described_class.new(bytes).frames.first.alpha).to eq([false, true, true, false])
  end

  it "handles the LZW next-code case before its dictionary entry exists" do
    # Codes clear,0,6,end describe three zero indices with code 6 still pending.
    bytes = sample(width: 3, height: 1, blocks: "\x02\x84\x0b\x00".b)

    expect(described_class.new(bytes).frames.first.alpha).to eq([false, false, false])
  end

  it "keeps every index opaque when the graphic control disables transparency" do
    expect(described_class.new(sample(transparent: false)).frames.first.alpha).to eq([true] * 4)
  end

  it "rejects offsets and interlacing instead of measuring misleading full-frame margins" do
    [sample(left: 1), sample(flags: 0x40)].each do |bytes|
      expect { described_class.new(bytes).frames }.to raise_error(ArgumentError, /full non-interlaced/)
    end
  end

  it "rejects truncated data, invalid LZW codes and a decoded canvas size mismatch" do
    [sample.byteslice(0...-2), sample(blocks: "\x01\x7c\x00".b), sample(width: 3, height: 2)].each do |bytes|
      expect { described_class.new(bytes).frames }.to raise_error(ArgumentError)
    end
  end

  it "rejects an oversized canvas and bytes after the trailer" do
    [sample(width: 129), sample + "extra"].each do |bytes|
      expect { described_class.new(bytes).frames }.to raise_error(ArgumentError)
    end
  end
end
