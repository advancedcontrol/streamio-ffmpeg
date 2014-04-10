require 'spec_helper'

describe FFMPEG::AudioStream do

  context 'given a Hash of valid video stream properties from an awesome movie' do

    before(:all) do
      str = IO.read(File.join(fixture_path, 'json', 'awesome movie.json'))
      raw_data = MultiJson.load(str, symbolize_keys: true)
      @data = raw_data[:streams].select { |stream| stream.key?(:codec_type) and stream[:codec_type] === 'audio' }.first
    end

    let(:awesome_audio_stream) { FFMPEG::AudioStream.new(@data) }

    {
        index: 0,
        codec_name: 'aac',
        codec_long_name: 'AAC (Advanced Audio Coding)',
        codec_tag: '0x6134706d',
        codec_tag_string: 'mp4a',
        codec_time_base: Rational(1, 44100),
        sample_fmt: 'fltp',
        sample_rate: 44100,
        channels: 2,
        channel_layout: 'stereo',
        bits_per_sample: 0,
        time_base: Rational(1, 44100),
        start_pts: 3822,
        start_time: 0.086667,
        duration_ts: 329728,
        duration: 7.476825,
        bit_rate: 75832,
        nb_frames: 322
    }.each do |property, value|
      it "#{property} should equal #{value}" do
        expect(awesome_audio_stream.send(property)).to eq value
      end
    end

  end

  {
      'awesome movie.mov' => 'Stream #0:0(und): Audio: aac (mp4a / 0x6134706d), 44100 Hz, stereo, fltp, 75 kb/s',
      'awesome_widescreen.mov' => 'Stream #0:1(und): Audio: aac (mp4a / 0x6134706d), 22050 Hz, mono, fltp, 31 kb/s',
      'bigbucksbunny_trailer_720p.mov' => 'Stream #0:1(eng): Audio: aac (mp4a / 0x6134706d), 48000 Hz, 5.1, fltp, 428 kb/s',
      'sideways movie.mov' => 'Stream #0:1(und): Audio: aac (mp4a / 0x6134706d), 44100 Hz, mono, fltp, 62 kb/s',
      'weird_aspect.small.mpg' => 'Stream #0:1[0x1c0]: Audio: mp2, 44100 Hz, stereo, s16p, 224 kb/s'
  }.each do |filename, value|
    describe '.to_s' do
      context "for '#{filename}'" do
        it do
          basename = File.basename(filename, '.*')
          str = IO.read(File.join(fixture_path, 'json', "#{basename}.json"))
          raw_data = MultiJson.load(str, symbolize_keys: true)
          data = raw_data[:streams].select { |stream| stream.key?(:codec_type) and stream[:codec_type] === 'audio' }.first
          stream = FFMPEG::AudioStream.new(data)
          expect(stream.to_s).to eq value
        end
      end
    end
  end

end