require 'spec_helper'

def make_video_stream_from_json(json_fixture)
  str = IO.read(File.join(fixture_path, 'json', json_fixture))
  raw_data = MultiJson.load(str, symbolize_keys: true)
  hash = raw_data[:streams].select { |stream| stream.key?(:codec_type) and stream[:codec_type] === 'video' }.first
  FFMPEG::VideoStream.new(hash)
end

describe FFMPEG::VideoStream do

  context 'given \'awesome movie.mov\'' do

    let(:video_stream) { make_video_stream_from_json('awesome movie.json') }

    {
        index: 1,
        codec_name: 'h264',
        codec_long_name: 'H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10',
        codec_tag: '0x31637661',
        codec_tag_string: 'avc1',
        codec_profile: 'Main',
        codec_time_base: Rational(1, 1200),
        width: 640,
        height: 480,
        sar: '1:1',
        sample_aspect_ratio: '1:1',
        dar: '4:3',
        display_aspect_ratio: '4:3',
        pixel_format: 'yuv420p',
        pix_fmt: 'yuv420p',
        colorspace: 'yuv420p',
        r_frame_rate: Rational(1200, 2),
        avg_frame_rate: Rational(24600, 1469),
        fps: Rational(24600, 1469),
        time_base: Rational(1, 600),
        start_pts: 0,
        start_time: 0.0,
        duration_ts: 4407,
        duration: 7.345000,
        bit_rate: 371185,
        bitrate: 371185,
        nb_frames: 123,
        language: 'und'
    }.each do |property, value|
      it "#{property} should equal #{value}" do
        expect(video_stream.send(property)).to eq value
      end
    end

    describe '#fps' do
      subject { video_stream.fps }

      it { should be_within(0.01).of(16.75) }
    end

    describe '#b_frames?' do
      subject { video_stream.b_frames? }

      it { should be_true }
    end

    describe '#rotate' do
      subject { video_stream.rotation }

      it { should be_nil }
    end

    describe '#to_s' do
      subject { video_stream.to_s }

      it { should eq 'Stream #0:1(und): Video: h264 (Main) (avc1 / 0x31637661), yuv420p, 640x480 [SAR 1:1 DAR 4:3], 371 kb/s, 16.75 fps, 600 tbr, 600 tbn, 1200 tbc' }
    end

    describe '#tbr' do
      subject { video_stream.tbr }

      it { should eq 600 }
    end

    describe '#tbn' do
      subject { video_stream.tbn }

      it { should eq 600 }
    end

    describe '#tbc' do
      subject { video_stream.tbc }

      it { should eq 1200 }
    end

  end

  context 'given \'awesome_widescreen.mov\'' do

    let(:video_stream) { make_video_stream_from_json('awesome_widescreen.json') }

    describe '#to_s' do
      subject { video_stream.to_s }

      it { should eq 'Stream #0:0(und): Video: h264 (Constrained Baseline) (avc1 / 0x31637661), yuv420p, 320x180 [SAR 1:1 DAR 16:9], 291 kb/s, 10 fps, 10 tbr, 10 tbn, 20 tbc' }
    end


    describe '#tbr' do
      subject { video_stream.tbr }

      it { should eq 10 }
    end

    describe '#tbn' do
      subject { video_stream.tbn }

      it { should eq 10 }
    end

    describe '#tbc' do
      subject { video_stream.tbc }

      it { should eq 20 }
    end

  end

  context 'given \'bigbucksbunny_trailer_720p.mov\'' do

    let(:video_stream) { make_video_stream_from_json('bigbucksbunny_trailer_720p.json') }

    describe '#to_s' do
      subject { video_stream.to_s }

      it { should eq 'Stream #0:0(eng): Video: h264 (Main) (avc1 / 0x31637661), yuv420p, 1280x720, 3945 kb/s, 25 fps, 25 tbr, 600 tbn, 1200 tbc' }
    end

    describe '#tbr' do
      subject { video_stream.tbr }

      it { should eq 25 }
    end

    describe '#tbn' do
      subject { video_stream.tbn }

      it { should eq 600 }
    end

    describe '#tbc' do
      subject { video_stream.tbc }

      it { should eq 1200 }
    end

  end

  context 'given \'no_audio.mov\'' do

    let(:video_stream) { make_video_stream_from_json('no_audio.json') }

    describe '#to_s' do
      subject { video_stream.to_s }

      it { should eq 'Stream #0:0(eng): Video: h264 (Main) (avc1 / 0x31637661), yuv420p, 640x480 [SAR 1:1 DAR 4:3], 374 kb/s, 16.90 fps, 15 tbr, 19200 tbn, 38400 tbc' }
    end

    describe '#tbr' do
      subject { video_stream.tbr }

      it { should eq 15 }
    end

    describe '#tbn' do
      subject { video_stream.tbn }

      it { should eq 19200 }
    end

    describe '#tbc' do
      subject { video_stream.tbc }

      it { should eq 38400 }
    end

  end

  context 'given \'sideways movie.mov\'' do

    let(:video_stream) { make_video_stream_from_json('sideways movie.json') }

    describe '#rotate' do
      subject { video_stream.rotation }

      it { should eq 90 }
    end

    describe '#to_s' do
      subject { video_stream.to_s }

      it { should eq 'Stream #0:0(und): Video: h264 (Baseline) (avc1 / 0x31637661), yuv420p, 640x480, 3757 kb/s, 24.04 fps, 24.08 tbr, 600 tbn, 1200 tbc' }
    end

    describe '#tbr' do
      subject { video_stream.tbr }

      it { should be_within(0.01).of(24.08) }
    end

    describe '#tbn' do
      subject { video_stream.tbn }

      it { should eq 600 }
    end

    describe '#tbc' do
      subject { video_stream.tbc }

      it { should eq 1200 }
    end

    describe '#sar' do
      subject { video_stream.sar }

      it { should eq '0:1' }
    end

    describe '#calculated_pixel_aspect_ratio' do
      subject { video_stream.calculated_pixel_aspect_ratio }

      it { should eq 1 }
    end

  end

  context 'given \'weird_aspect.small.mpg\'' do

    let(:video_stream) { make_video_stream_from_json('weird_aspect.small.json') }

    describe '#to_s' do
      subject { video_stream.to_s }

      it { should eq 'Stream #0:0[0x1e0]: Video: mpeg1video, yuv420p, 352x288 [SAR 64:45 DAR 704:405], 1500 kb/s, 25 fps, 25 tbr, 90k tbn, 25 tbc' }
    end

    describe '#tbr' do
      subject { video_stream.tbr }

      it { should eq 25 }
    end

    describe '#tbn' do
      subject { video_stream.tbn }

      it { should eq 90000 }
    end

    describe '#tbc' do
      subject { video_stream.tbc }

      it { should eq 25 }
    end

    describe '#dar' do
      subject { video_stream.dar }

      it { should eq '704:405' }
    end

    describe '#calculated_aspect_ratio' do
      subject { video_stream.calculated_aspect_ratio }

      it { should be_within(0.0000000000001).of(1.7382716049382) }
    end

    describe '#sar' do
      subject { video_stream.sar }

      it { should eq '64:45' }
    end

    describe '#calculated_pixel_aspect_ratio' do
      subject { video_stream.calculated_pixel_aspect_ratio }

      it { should be_within(0.01).of(1.42) }
    end

  end

  context 'given Metal_gear-aspect-ratio-fail-BeAQfhzGg9c.mp4' do

    let(:video_stream) { make_video_stream_from_json('Metal_gear-aspect-ratio-fail.mov-BeAQfhzGg9c.json') }

    describe '#dar' do
      subject { video_stream.dar }

      it { should eq '0:1' }
    end

    describe '#calculated_aspect_ratio' do
      subject { video_stream.calculated_aspect_ratio }

      it { should be_within(0.01).of(1.77777) }
    end

  end

  context 'given a Hash of BMP' do

    let(:image) { make_video_stream_from_json('image.bmp.json') }

    it 'should not raise any errors' do
      expect { image }.not_to raise_error
    end

    describe '.to_s' do

      subject { image.to_s }

      it { should eq 'Stream #0:0: Video: bmp, bgr24, 400x200, 25 tbr, 25 tbn, 25 tbc' }

    end

    describe '.image?' do

      subject { image.image? }

      it { should be_true }

    end

  end

  context 'given a Hash of JPG' do

    let(:image) { make_video_stream_from_json('image.jpg.json') }

    it 'should not raise any errors' do
      expect { image }.not_to raise_error
    end

    describe '.to_s' do

      subject { image.to_s }

      it { should eq 'Stream #0:0: Video: mjpeg, yuvj420p, 640x480 [SAR 1:1 DAR 4:3], 25 tbr, 25 tbn, 25 tbc' }

    end

    describe '.image?' do

      subject { image.image? }

      it { should be_true }

    end

  end

  context 'given a Hash of PNG' do

    let(:image) { make_video_stream_from_json('image.png.json') }

    it 'should not raise any errors' do
      expect { image }.not_to raise_error
    end

    describe '.to_s' do

      subject { image.to_s }

      it { should eq 'Stream #0:0: Video: png, rgb24, 320x240 [SAR 1:1 DAR 4:3], 25 tbr, 25 tbn, 25 tbc' }

    end

    describe '.image?' do

      subject { image.image? }

      it { should be_true }

    end

  end

end