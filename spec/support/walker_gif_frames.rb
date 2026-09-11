# frozen_string_literal: true

require "stringio"

# Test-only GIF89a reader for the shipped full-frame, non-interlaced walkers.
# It decodes palette indices into row-major opaque/transparent masks, not RGB
# or composited partial frames. Unsupported layouts and malformed data reject.
class WalkerGifFrames
  Frame = Data.define(:width, :height, :alpha)

  def self.read(path)
    new(File.binread(path)).frames
  end

  def initialize(bytes)
    @input = StringIO.new(bytes.b)
  end

  def frames
    raise ArgumentError, "Expected GIF89a" unless read(6) == "GIF89a"
    @width, @height, flags, = read(7).unpack("v2C3")
    raise ArgumentError, "Unsupported GIF size" unless @width.between?(1, 128) && @height.between?(1, 128)
    @global_colors = palette_size(flags)
    result = []
    loop do
      case byte
      when 0x21 then extension
      when 0x2c then result << frame
      when 0x3b then break
      else raise ArgumentError, "Unsupported GIF block"
      end
    end
    raise ArgumentError, "Empty or trailing GIF data" if result.empty? || !@input.eof?
    result
  end

  private

  def read(length)
    data = @input.read(length)
    raise ArgumentError, "Truncated GIF" unless data&.bytesize == length
    data
  end

  def byte
    read(1).getbyte(0)
  end

  def palette_size(flags)
    return if flags & 0x80 == 0
    count = 1 << ((flags & 7) + 1)
    read(count * 3)
    count
  end

  def sub_blocks
    data = +"".b
    while (length = byte).positive?
      data << read(length)
    end
    data
  end

  def extension
    case byte
    when 0xf9
      control = read(6).bytes
      raise ArgumentError, "Malformed GIF control" unless control.first == 4 && control.last.zero?
      @transparent = control[1] & 1 == 1 ? control[4] : nil
    when 0xff, 0xfe then sub_blocks
    else raise ArgumentError, "Unsupported GIF extension"
    end
  end

  def frame
    left, top, width, height, flags = read(9).unpack("v4C")
    unless left.zero? && top.zero? && width == @width && height == @height && flags & 0x40 == 0
      raise ArgumentError, "Expected full non-interlaced GIF frame"
    end
    colors = palette_size(flags) || @global_colors
    raise ArgumentError, "Missing GIF palette" unless colors
    minimum = byte
    indices = decode(sub_blocks, minimum, width * height)
    if indices.any? { |index| index >= colors } || (@transparent && @transparent >= colors)
      raise ArgumentError, "GIF palette index out of bounds"
    end
    alpha = indices.map { |index| index != @transparent }
    @transparent = nil
    Frame.new(width:, height:, alpha:)
  end

  def decode(data, minimum, pixel_count)
    raise ArgumentError, "Unsupported GIF LZW code size" unless minimum.between?(2, 8)
    clear = 1 << minimum
    finish = clear + 1
    code_size = minimum + 1
    next_code = finish + 1
    dictionary = previous = nil
    output = []
    offset = 0
    loop do
      raise ArgumentError, "Truncated GIF LZW data" if offset + code_size > data.bytesize * 8
      packed = data.byteslice(offset / 8, 3).ljust(4, "\0").unpack1("V")
      code = (packed >> (offset % 8)) & ((1 << code_size) - 1)
      offset += code_size
      if code == clear
        dictionary = Array.new(clear) { |index| [index] }
        code_size, next_code, previous = minimum + 1, finish + 1, nil
      elsif code == finish
        break
      else
        entry = dictionary && dictionary[code]
        entry ||= previous + [previous.first] if previous && code == next_code
        raise ArgumentError, "Invalid GIF LZW code" unless entry
        output.concat(entry)
        raise ArgumentError, "GIF frame exceeds canvas" if output.length > pixel_count
        if previous && next_code < 4096
          dictionary[next_code] = previous + [entry.first]
          next_code += 1
          code_size += 1 if next_code == (1 << code_size) && code_size < 12
        end
        previous = entry
      end
    end
    raise ArgumentError, "Incomplete GIF frame" unless output.length == pixel_count
    output
  end
end
