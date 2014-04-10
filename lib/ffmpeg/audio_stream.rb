module FFMPEG

  class AudioStream

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
    #   @return [Integer]
    # @!attribute [r] codec_time_base
    #   @return [Rational]
    # @!attribute [r] sample_fmt
    #   @return [String]
    # @!attribute [r] sample_rate
    #   @return [Integer]
    # @!attribute [r] channels
    #   @return [Integer]
    # @!attribute [r] channel_layout
    #   @return [String]
    # @!attribute [r] bits_per_sample
    #   @return [Integer]
    # @!attribute [r] time_base
    #   @return [Rational]
    # @!attribute [r] start_pts
    #   @return [Integer]
    # @!attribute [r] start_time
    #   @return [Float]
    # @!attribute [r] duration_ts
    #   @return [Integer]
    # @!attribute [r] duration
    #   @return [Float]
    # @!attribute [r] bit_rate
    #   @return [Fixnum]
    # @!attribute [r] bitrate
    #   @return [Fixnum] Alias to bit_rate
    # @!attribute [r] language
    #   @return [String]
    # @!attribute [r] lang
    #   @return [String] Alias to language
    attr_reader :index
    attr_reader :codec_name, :codec_long_name, :codec_tag, :codec_tag_string, :codec_time_base
    attr_reader :sample_fmt, :sample_rate, :bits_per_sample
    attr_reader :channels, :channel_layout
    attr_reader :time_base, :start_pts, :start_time, :duration_ts, :duration, :bit_rate, :nb_frames
    attr_reader :language

    alias_method :bitrate, :bit_rate
    alias_method :lang, :language

    def initialize(hash)
      @index = hash[:index]
      @codec_name = hash[:codec_name]
      @codec_long_name = hash[:codec_long_name]
      @codec_tag = hash[:codec_tag]
      @codec_tag_string = hash[:codec_tag_string]
      @codec_time_base = Rational(hash[:codec_time_base])
      @sample_fmt = hash[:sample_fmt]
      @sample_rate = hash[:sample_rate].to_i
      @channels = hash[:channels]
      @channel_layout = hash[:channel_layout]
      @bits_per_sample = hash[:bits_per_sample]
      @time_base = Rational(hash[:time_base])
      @start_pts = hash[:start_pts]
      @start_time = hash[:start_time].to_f
      @duration_ts = hash[:duration_ts]
      @duration = hash[:duration].to_f
      @bit_rate = hash[:bit_rate].to_i
      @nb_frames = hash[:nb_frames].to_i

      @id = hash[:id]

      if hash.key?(:tags)
        @language = hash[:tags][:language]
      end
    end

    # Format the audio stream into a string similar to the output of ffmpeg
    # @return [String]
    def to_s
      stream_id = if @id
                    "Stream #0:#{index}[#{@id}]"
                  else
                    "Stream #0:#{index}(#{lang})"
                  end

      display_codec = if codec_tag.hex != 0
                        "#{codec_name} (#{codec_tag_string} / #{codec_tag})"
                      else
                        "#{codec_name}"
                      end

      display_bit_rate = "#{bit_rate / 1000} kb/s"

      "#{stream_id}: Audio: #{display_codec}, #{sample_rate} Hz, #{channel_layout}, #{sample_fmt}, #{display_bit_rate}"
    end

  end

end
