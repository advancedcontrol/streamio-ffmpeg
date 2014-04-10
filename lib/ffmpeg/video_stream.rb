module FFMPEG

  class VideoStream

    # TODO Fully document the parameters on the VideoStream
    # @!attribute [r] index
    #   @return [Fixnum] the index of the video stream in the container
    # @!attribute [r] codec_name
    #   @return [String]
    # @!attribute [r] codec_long_name
    #   @return [String]
    # @!attribute [r] codec_tag
    #   @return [String]
    # @!attribute [r] codec_tag_string
    #   @return [String]
    # @!attribute [r] codec_profile
    #   @return [Integer]
    # @!attribute [r] codec_time_base
    #   @return [Rational]
    # @!attribute [r] width
    #   @return [Fixnum]
    # @!attribute [r] height
    #   @return [Fixnum]
    # @!attribute [r] sample_aspect_ratio
    #   @return [String]
    # @!attribute [r] sar
    #   @return [String] Alias to sample_aspect_ratio
    # @!attribute [r] display_aspect_ratio
    #   @return [String]
    # @!attribute [r] dar
    #   @return [String] Alias to display_aspect_ratio
    # @!attribute [r] pix_fmt
    #   @return [String]
    # @!attribute [r] pixel_format
    #   @return [String] Alias to pix_fmt
    # @!attribute [r] colorspace
    #   @return [String] Alias to pix_fmt
    # @!attribute [r] r_frame_rate Real base framerate of the stream
    #   @see http://ffmpeg.org/doxygen/trunk/structAVStream.html#ad63fb11cc1415e278e09ddc676e8a1ad
    #   @return [Rational]
    # @!attribute [r] tbr
    #   @return [Rational] Alias to r_frame_rate
    # @!attribute [r] avg_frame_rate
    #   @see http://ffmpeg.org/doxygen/trunk/structAVStream.html#a946e1e9b89eeeae4cab8a833b482c1ad
    #   @return [Rational]
    # @!attribute [r] fps
    #   @return [Rational] Alias to avg_frame_rate
    # @!attribute [r] time_base
    #   @return [Rational]
    # @!attribute [r] start_pts
    #   @return [Fixnum]
    # @!attribute [r] start_time
    #   @return [Float]
    # @!attribute [r] duration_ts
    #   @return [Fixnum]
    # @!attribute [r] duration
    #   @return [Float]
    # @!attribute [r] bit_rate
    #   @return [Fixnum]
    # @!attribute [r] bitrate
    #   @return [Fixnum] Alias to bit_rate
    # @!attribute [r] nb_frames
    #   @return [Fixnum]
    # @!attribute [r] language
    #   @return [String]
    # @!attribute [r] lang
    #   @return [String] Alias to language
    # @!attribute [r] rotate
    #   @return [Fixnum]
    # @!attribute [r] rotation
    #   @return [Fixnum] Alias to rotate
    attr_reader :index
    attr_reader :codec_name, :codec_long_name, :codec_tag, :codec_tag_string, :codec_profile, :codec_time_base
    attr_reader :width, :height, :sample_aspect_ratio, :display_aspect_ratio, :pix_fmt, :r_frame_rate, :avg_frame_rate
    attr_reader :time_base, :start_pts, :start_time, :duration_ts, :duration
    attr_reader :bit_rate, :nb_frames
    attr_reader :language, :rotate

    alias_method :sar, :sample_aspect_ratio
    alias_method :dar, :display_aspect_ratio
    alias_method :pixel_format, :pix_fmt
    alias_method :colorspace, :pix_fmt
    alias_method :tbr, :r_frame_rate
    alias_method :fps, :avg_frame_rate
    alias_method :bitrate, :bit_rate
    alias_method :lang, :language
    alias_method :rotation, :rotate

    ##
    # Initialize an instance with the Hash returned from parsing the JSON output of ffprobe
    def initialize(hash)
      @index = hash[:index]
      @codec_name = hash[:codec_name]
      @codec_long_name = hash[:codec_long_name]
      @codec_tag = hash[:codec_tag]
      @codec_tag_string = hash[:codec_tag_string]
      @codec_profile = hash[:profile]
      @codec_time_base = Rational(hash[:codec_time_base])
      @width = hash[:width].to_i
      @height = hash[:height].to_i
      @b_frames = hash[:has_b_frames].to_i
      @sample_aspect_ratio = hash[:sample_aspect_ratio]
      @display_aspect_ratio = hash[:display_aspect_ratio]
      @pix_fmt = hash[:pix_fmt]
      @r_frame_rate = Rational(hash[:r_frame_rate])
      # For some reason ffmpeg returns a Rational number with a zero in the denominator
      @avg_frame_rate = if hash[:avg_frame_rate] === '0/0'
                          Rational(0)
                        else
                          Rational(hash[:avg_frame_rate])
                        end
      @time_base = Rational(hash[:time_base])
      @start_pts = hash[:start_pts].to_i
      @start_time = hash[:start_time].to_f
      @duration_ts = hash[:duration_ts].to_i
      @duration = hash[:duration].to_f
      @bit_rate = hash[:bit_rate].to_i
      @nb_frames = hash[:nb_frames].to_i

      @id = hash[:id]

      if hash.key?(:tags)
        @language = hash[:tags][:language]
        @rotate = (hash[:tags].key?(:rotate)) ? hash[:tags][:rotate].to_i : nil
      end
    end

    ##
    # The time base in AVStream that has come from the container
    # @see http://stackoverflow.com/questions/3199489/meaning-of-ffmpeg-output-tbc-tbn-tbr
    # @see http://ffmpeg-users.933282.n4.nabble.com/What-does-the-output-of-ffmpeg-mean-tbr-tbn-tbc-etc-td941538.html
    # @return [Rational]
    def tbn
      1 / time_base
    end

    ##
    # The time base in AVCodecContext for the codec used for a particular stream
    # @see http://stackoverflow.com/questions/3199489/meaning-of-ffmpeg-output-tbc-tbn-tbr
    # @see http://ffmpeg-users.933282.n4.nabble.com/What-does-the-output-of-ffmpeg-mean-tbr-tbn-tbc-etc-td941538.html
    # @return [Rational]
    def tbc
      1 / codec_time_base
    end

    ##
    # Determine if the codec is valid. From observation it appears that a
    # @return [TrueClass|FalseClass]
    def supported?
      false
    end

    # @return [TrueClass|FalseClass]
    def b_frames?
      !!(@b_frames === 1)
    end

    # @return [String?]
    def resolution
      unless width.nil? or height.nil?
        "#{width}x#{height}"
      end
    end

    def calculated_aspect_ratio
      aspect_from_dar || aspect_from_dimensions
    end

    def calculated_pixel_aspect_ratio
      aspect_from_sar || 1
    end

    # @return [TrueClass|FalseClass]
    def image?
      !!(codec_name =~ /bmp|png|mjpeg/)
    end

    # Format the video stream into a string similar to the output of ffmpeg
    # @return [String]
    def to_s
      stream_id = if image?
                    "Stream #0:#{index}"
                  elsif @id
                    "Stream #0:#{index}[#{@id}]"
                  else
                    "Stream #0:#{index}(#{lang})"
                  end

      display_codec = if codec_tag.hex != 0
                        "#{codec_name} (#{codec_profile}) (#{codec_tag_string} / #{codec_tag})"
                      else
                        "#{codec_name}"
                      end

      display_resolution = if sar === '0:1' or dar === '0:1'
                             resolution
                           else
                             "#{resolution} [SAR #{sar} DAR #{dar}]"
                           end

      display_bit_rate = "#{bitrate / 1000} kb/s"

      display_fps = VideoStream.format_rational(fps, 'fps')

      display_tbr = VideoStream.format_rational(tbr, 'tbr')

      display_tbn = VideoStream.format_rational(tbn, 'tbn')

      if image?
        "#{stream_id}: Video: #{display_codec}, #{pix_fmt}, #{display_resolution}, #{display_tbr}, #{display_tbn}, #{tbc.to_i} tbc"
      else
        "#{stream_id}: Video: #{display_codec}, #{pix_fmt}, #{display_resolution}, #{display_bit_rate}, #{display_fps}, #{display_tbr}, #{display_tbn}, #{tbc.to_i} tbc"
      end
    end

    private

    ##
    # Determine if the Rational number has a fractional part
    # @param rational [Rational] the number to test
    # @return [TrueClass|FalseClass]
    def self.fractional?(rational)
      !!(rational.numerator % rational.denominator != 0)
    end

    ##
    # @return [String]
    def self.format_rational(rational, suffix)
      if self.fractional?(rational)
        "#{'%.2f' % rational} #{suffix}"
      elsif rational % 1000 === 0
        "#{rational.to_i / 1000}k #{suffix}"
      else
        "#{rational.to_i} #{suffix}"
      end
    end

    protected
    def aspect_from_dar
      return nil unless dar
      w, h = dar.split(":")
      aspect = w.to_f / h.to_f
      aspect.zero? ? nil : aspect
    end

    def aspect_from_sar
      return nil unless sar
      w, h = sar.split(":")
      aspect = w.to_f / h.to_f
      aspect.zero? ? nil : aspect
    end

    def aspect_from_dimensions
      aspect = width.to_f / height.to_f
      aspect.nan? ? nil : aspect
    end

  end

end