require 'open3'
require 'shellwords'
require 'ffmpeg/transcoders/autorotator'
require 'ffmpeg/transcoders/scaler'

module FFMPEG
  class ProcessError < Error; end

  class Transcoder
    include FFMPEG::Transcoders::Autorotator
    include FFMPEG::Transcoders::Scaler


    @@timeout = 30

    def self.timeout=(time)
      @@timeout = time
    end

    def self.timeout
      @@timeout
    end


    attr_reader :output


    def initialize(movie, output_file, options = EncodingOptions.new, transcoder_options = {:enlarge => true})
      @movie = movie
      @output_file = output_file

      if options.is_a?(String) || options.is_a?(EncodingOptions)
        @raw_options = options
      elsif options.is_a?(Hash)
        @raw_options = EncodingOptions.new(options)
      else
        raise ArgumentError, "Unknown options format '#{options.class}', should be either EncodingOptions, Hash or String."
      end

      @transcoder_options = transcoder_options
      @errors = []

      apply_transcoder_options
    end

    def run(&block)
      transcode_movie(&block)
      if @transcoder_options[:validate]
        if @output_file =~ /%[0-9]*d/
          @output_file = Dir.glob(@output_file.gsub(/%[0-9]*d/, "*"))
        end
        validate_output_file(&block)
        return encoded
      else
        return nil
      end
    end

    def encoding_succeeded?
      if @output_file.is_a?(Array)
        @errors << "no output file created" and return false unless !@output_file.empty?
        @errors << "encoded file is invalid" and return false unless !encoded.map{|e| e.valid?}.include?(false)
      else
        @errors << "no output file created" and return false unless File.exists?(@output_file)
        @errors << "encoded file is invalid" and return false unless encoded.valid?
      end
      true
    end

    def encoded
      if @output_file.is_a?(Array)
        @encoded ||= @output_file.map!{|file| Movie.new(file)}
      else
        @encoded ||= Movie.new(@output_file)
      end
    end


    private


    # frame= 4855 fps= 46 q=31.0 size=   45306kB time=00:02:42.28 bitrate=2287.0kbits/
    def transcode_movie
      @command = "#{FFMPEG.ffmpeg_binary} -y -i #{Shellwords.escape(@movie.path)} #{@raw_options} #{Shellwords.escape(@output_file)}"
      FFMPEG.logger.info("Running transcoding...\n#{@command}\n")
      @output = ""
      process = nil

      Open3.popen3(@command) do |stdin, stdout, stderr, wait_thr|
        stdout.close

        begin
          yield(0.0) if block_given?
          next_line = Proc.new do |line|
            fix_encoding(line)
            @output << line
            if line.include?("time=")
              if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
                time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
              else # better make sure it wont blow up in case of unexpected output
                time = 0.0
              end
              progress = time / @movie.duration
              yield(progress) if block_given?
            end
          end

          if @@timeout
            stderr.each_with_timeout(wait_thr.pid, @@timeout, 'size=', &next_line)
          else
            stderr.each('size=', &next_line)
          end

        rescue Timeout::Error => e
          FFMPEG.logger.error "Process hung...\n@command\n#{@command}\nOutput\n#{@output}\n"
          raise Error, "Process hung. Full output: #{@output}"
        end

        # Grab the Process::Status object of the thread 
        process = wait_thr.value
      end

      unless process && process.exited? && process.exitstatus == 0
        msg = if process && process.exited?
          "Transcoding failed with exit code: #{process.exitstatus}. Command was: '#{@command}'"
        else
          "Transcoding failed as the process was terminated prematurely. Command was: '#{@command}'"
        end
        
        raise ProcessError, msg
      end
    end

    def validate_output_file(&block)
      if encoding_succeeded?
        yield(1.0) if block_given?
        FFMPEG.logger.info "Transcoding of #{@movie.path} to #{@output_file} succeeded\n"
      else
        errors = "Errors: #{@errors.join(", ")}. "
        FFMPEG.logger.error "Failed encoding...\n#{@command}\n\n#{@output}\n#{errors}\n"
        raise Error, "Failed encoding.#{errors}Full output: #{@output}"
      end
    end

    def apply_transcoder_options
      apply_autorotate
      changes_orientation = changes_orientation?

      # if true runs #validate_output_file
      @transcoder_options[:validate] = @transcoder_options.fetch(:validate) { true }
      apply_preserve_aspect_ratio(changes_orientation)
    end

    def fix_encoding(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding("ISO-8859-1")
    end
  end
end