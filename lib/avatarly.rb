require 'rvg/rvg'
require 'rfc822'
require 'pathname'
require 'unicode_utils'

class Avatarly
  BACKGROUND_COLORS = [
    "#C91F37", "#DC3023", "#9D2933", "#CF000F", "#E68364", "#F22613", "#CF3A24", "#C3272B", "#8F1D21", "#D24D57",
    "#F08F90", "#F47983", "#DB5A6B", "#C93756", "#FCC9B9", "#FFB3A7", "#F62459", "#F58F84", "#875F9A", "#5D3F6A",
    "#89729E", "#763568", "#8D608C", "#A87CA0", "#5B3256", "#BF55EC", "#8E44AD", "#9B59B6", "#BE90D4", "#4D8FAC",
    "#5D8CAE", "#22A7F0", "#19B5FE", "#59ABE3", "#48929B", "#317589", "#89C4F4", "#4B77BE", "#1F4788", "#003171",
    "#044F67", "#264348", "#8DB255", "#5B8930", "#6B9362", "#407A52", "#006442", "#87D37C", "#26A65B", "#26C281",
    "#049372", "#2ABB9B", "#16A085", "#36D7B7", "#03A678", "#4DAF7C", "#D9B611", "#F3C13A", "#F7CA18", "#E2B13C",
    "#A17917", "#FFA400", "#E08A1E", "#FFB61E", "#FAA945", "#FFA631", "#FFB94E", "#E29C45", "#F9690E", "#CA6924",
    "#F5AB35", "#BFBFBF", "#BDC3C7", "#757D75", "#ABB7B7", "#6C7A89", "#95A5A6"
  ].freeze

  class << self
    def generate_avatar(text, opts={})
      if opts[:lang]
        text = UnicodeUtils.upcase(initials(text.to_s.gsub(/[^[[:word:]] ]/,'').strip, opts), opts[:lang])
      else
        text = initials(text.to_s.gsub(/[^\w ]/,'').strip, opts).upcase
      end
      generate_image(text, parse_options(opts)).to_blob
    end

    def root
      File.expand_path '../..', __FILE__
    end

    def lib
      File.join root, 'lib'
    end

    private

    def fonts
      File.join root, 'assets/fonts'
    end

    def generate_image(text, opts)
      image = Magick::RVG.new(opts[:size], opts[:size]).viewbox(0, 0, opts[:size], opts[:size]) do |canvas|
        canvas.background_fill = opts[:background_color]
      end.draw
      image.format = opts[:format]
      draw_text(image, text, opts) if text.length > 0
      image
    end

    def draw_text(canvas, text, opts)
      Magick::Draw.new do |md|
        md.pointsize = opts[:font_size]
        md.font = opts[:font]
        md.fill = opts[:font_color]
        md.gravity = Magick::CenterGravity
      end.annotate(canvas, 0, 0, 0, opts[:vertical_offset], text)
    end

    def initials(text, opts)
      if opts[:separator]
        initials_for_separator(text, opts[:separator])
      elsif text.is_email?
        initials_for_separator(text.split("@").first, ".")
      elsif text.include?(" ")
        initials_for_separator(text, " ")
      else
        initials_for_separator(text, ".")
      end
    end

    def initials_for_separator(text, separator)
      if text.include?(separator)
        text.split(separator).compact.map{|part| part[0]}.join
      else
        text[0] || ''
      end
    end

    def default_options
      { background_color: BACKGROUND_COLORS.sample,
        font_color: '#FFFFFF',
        size: 32,
        vertical_offset: 0,
        font: "#{fonts}/Roboto.ttf",
        format: "png" }
    end

    def parse_options(opts)
      opts = default_options.merge(opts)
      opts[:size] = opts[:size].to_i
      opts[:font] = default_options[:font] unless Pathname(opts[:font]).exist?
      opts[:font_size] ||= opts[:size] / 2
      opts[:font_size] = opts[:font_size].to_i
      opts[:vertical_offset] = opts[:vertical_offset].to_i
      opts
    end
  end
end
