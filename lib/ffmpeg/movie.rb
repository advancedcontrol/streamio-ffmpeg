require 'time'
require 'multi_json'

module FFMPEG
  class Movie
    attr_reader :path, :duration, :time, :bitrate, :creation_time

    # @!attribute [r] video_streams
    #   @return [Array<FFMPEG::VideoStreams>] Array of video streams parsed
    attr_reader :video_streams
    # @!attribute [r] audio_streams
    #   @return [Array<FFMPEG::AudioStreams>] Array of audio streams parsed
    attr_reader :audio_streams
    attr_reader :container

    def initialize(path)
      raise Errno::ENOENT, "the file '#{path}' does not exist" unless File.exists?(path)

      @path = path

      # ffmpeg will output to stderr
      command = "#{FFMPEG.ffprobe_binary} -i #{Shellwords.escape(path)} -print_format json -show_format -show_streams -show_error"
      std_output = ''
      std_error = ''

      Open3.popen3(command) do |stdin, stdout, stderr|
        std_output = stdout.read unless stdout.nil?
        std_error = stderr.read unless stderr.nil?
      end

      fix_encoding(std_output)

      metadata = MultiJson.load(std_output, symbolize_keys: true)

      if metadata.key?(:error)

        @duration = 0

      else

        @video_streams = metadata[:streams]
                          .select { |stream| stream.key?(:codec_type) and stream[:codec_type] === 'video' }
                          .map { |vs_hash| FFMPEG::VideoStream.new(vs_hash) }

        @audio_streams = metadata[:streams]
                          .select { |stream| stream.key?(:codec_type) and stream[:codec_type] === 'audio' }
                          .map { |as_hash| FFMPEG::AudioStream.new(as_hash) }

        @container = metadata[:format][:format_name]

        @duration = metadata[:format][:duration].to_f

        @time = metadata[:format][:start_time].to_f

        @creation_time = if metadata[:format].key?(:tags) and metadata[:format][:tags].key?(:creation_time)
                           Time.parse(metadata[:format][:tags][:creation_time])
                         else
                           nil
                         end

        @bitrate = metadata[:format][:bit_rate].to_i

      end

      @invalid = true if metadata.key?(:error)

      # Check this error isn't a stream we care about (most likely a data stream)
      if std_error.include?("Unsupported codec")
        matches = std_error.scan(/Unsupported\scodec\swith\sid\s(\d)\sfor\sinput\sstream\s(\d)/i)
        matches.each do |check|
          codec_id = check[0]
          codec_stream = check[1]

          if codec_id && codec_stream
            stream = metadata[:streams][codec_stream.to_i]
            if stream[:codec_type] === 'video' || stream[:codec_type] === 'audio'
              @invalid = true
              return
            end
          else
            @invalid = true
            return
          end
        end
      end
      @invalid = true if std_error.include?("is not supported")
      @invalid = true if std_error.include?("could not find codec parameters")
    end

    ##
    # Return a string description of the first audio stream for the Movie instance. Provided the movie instance is
    # valid and has audio streams.
    #
    # This is really just a convenience method to AudioStream#to_s
    # @return [String?] A string description of the first audio stream
    def audio_stream
      audio_streams.first.to_s.match(/Audio:\s+(.*)$/)[1] unless @invalid or audio_streams.empty?
    end

    ##
    # Return the name of the audio codec of the first audio stream for the Movie instance. Provided the movie instance
    # is valid and has audio streams.
    #
    # This is really just a convenience method to AudioStream#codec_name
    # @return [String?] The audio codec of the first audio stream.
    def audio_codec
      audio_streams.first.codec_name unless @invalid or audio_streams.empty?
    end

    ##
    # Return the first audio streams bitrate. Provided the movie instance is valid and has audio streams.
    #
    # This is really just a convenience method to AudioStream#bitrate
    # @return [Fixnum?] The bit rate of the first audio stream
    def audio_bitrate
      firstStream = audio_streams.first
      firstStream.nil? ? 0 : firstStream.bitrate
    end

    ##
    #
    # This is really just a convenience method to AudioStream#sample_rate
    # @return [Integer?] The audio codec sample rate in Hertz
    def audio_sample_rate
      audio_streams.first.sample_rate unless @invalid or audio_streams.empty?
    end

    ##
    # Return the number of audio channels of the first audio stream.
    #
    # This is really just a convenience method to AudioStream#channels
    # @return [Integer?] The number of audio channels of the first audio stream
    def audio_channels
      audio_streams.first.channels unless @invalid or audio_streams.empty?
    end

    ##
    # Return a string description of the first video stream for the Movie instance. Provided the movie instance is
    # valid and has video streams.
    #
    # This is really just a convenience method to VideoStream#to_s
    # @return [String?] A string description of the first video stream
    def video_stream
      video_streams.first.to_s.match(/Video:\s+(.*)$/)[1] unless @invalid or video_streams.empty?
    end

    ##
    # The name of the first codec for the Movie instance. Provided the movie instance is valid and has video streams.
    #
    # This is really just a convenience method to VideoStream#codec_name
    # @return [String?] The name of the codec for the first video stream
    def video_codec
      video_streams.first.codec_name unless @invalid or video_streams.empty?
    end

    ##
    #
    # This is really just a convenience method to VideoStream#video_bitrate
    # @return [Fixnum?] The bit rate of the first video stream
    def video_bitrate
      video_streams.first.bitrate unless @invalid or video_streams.empty?
    end

    ##
    #
    # This is really just a convenience method to VideoStream#colorspace
    # @return [String?] The pixel format of the first video stream
    def colorspace
      video_streams.first.colorspace unless @invalid or video_streams.empty?
    end

    ##
    #
    # This is really just a convenience method to VideoStream#width
    def width
      video_streams.first.width unless @invalid or video_streams.empty?
    end

    ##
    #
    # This is really just a convenience method to VideoStream#height
    def height
      video_streams.first.height unless @invalid or video_streams.empty?
    end

    ##
    #
    # This is really just a convenience method to VideoStream#sar
    def sar
      video_streams.first.sar unless @invalid or video_streams.empty?
    end

    ##
    #
    # This is really just a convenience method to VideoStream#dar
    def dar
      video_streams.first.dar unless @invalid or video_streams.empty?
    end

    ##
    #
    # This is really just a convenience method to VideoStream#avg_frame_rate
    def frame_rate
      video_streams.first.avg_frame_rate unless @invalid or video_streams.empty?
    end

    ##
    #
    # This is really just a convenience method to VideoStream#rotation
    def rotation
      video_streams.first.rotation unless @invalid or video_streams.empty?
    end

    def valid?
      not @invalid
    end

    def resolution
      unless width.nil? or height.nil?
        "#{width}x#{height}"
      end
    end

    def calculated_aspect_ratio
      video_streams.first.calculated_aspect_ratio unless @invalid or video_streams.empty?
    end

    def calculated_pixel_aspect_ratio
      video_streams.first.calculated_pixel_aspect_ratio unless @invalid or video_streams.empty?
    end

    def size
      File.size(@path)
    end

    def audio_channel_layout
      # TODO Whenever support for ffmpeg/ffprobe 1.2.1 is dropped this is no longer needed
      @audio_channel_layout || case(audio_channels)
                                 when 1
                                   'stereo'
                                 when 2
                                   'stereo'
                                 when 6
                                   '5.1'
                                 else
                                   'unknown'
                               end
    end

    def transcode(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      @transcoder = Transcoder.new(self, output_file, options, transcoder_options)
      @transcoder.run &block
    end

    def transcoder_output
      @transcoder.output if @transcoder
    end

    def screenshot(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      @transcoder = Transcoder.new(self, output_file, options.merge(screenshot: true), transcoder_options)
      @transcoder.run &block
    end


    protected


    def fix_encoding(output)
      output[/test/] # Running a regexp on the string throws error if it's not UTF-8
    rescue ArgumentError
      output.force_encoding("ISO-8859-1")
    end
  end
end
