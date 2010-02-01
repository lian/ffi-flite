require 'bacon'; Bacon.summary_on_exit

def generate_test_riff(filename)
  require 'ffi-flite'
  FFI::Flite.init.should == 0
  voice = FFI::Flite::Voice.init_kal16
  voice.should.not.be.null?

  u = FFI::Flite.synth_text 'test utterance', voice
  w = FFI::Flite.utt_wave(u)
  u.should.not.be.null?
  w.should.not.be.null?

  FFI::Flite.save_wave_riff(w, filename).should == 0
  FFI::Flite.delete_utterance(u)
end


describe 'RIFF Wave Format' do
  @filename = 'test_utterance.riff'

  it 'generate riff if missing' do
    !File.exists?(@filename) ? generate_test_riff(@filename) : true.should == true
  end

  it 'loads test riff' do
    # load save_wave_riff
    @riff = File.read(@filename).bytes.to_a
    @riff.size.should >= 44
    @riff.size.should == 41156
  end

  def int_chunk(offset, length)
    @riff[offset...offset+length].reverse.map{|i|'%x'%[i]}.join.to_i(16)
  end

  def str_chunk(offset, length)
    @riff[offset...offset+length].map(&:chr).join
  end

  it 'contains riff header' do
    # file size
    @riff.size.should >= 48  # == 41156 for test_utterance.riff

    # Offset RIFF-Header
    # 0 4 'RIFF'
    str_chunk(0,4).should == 'RIFF'

    # 4 4 <Dateigröße - 8>
    int_chunk(4,4).should == @riff.size - 8

    # 8 4 'WAVE'
    str_chunk(8,4).should == 'WAVE'
  end

  it 'contains fmt header' do
    # 12  4 'fmt '  Header-Signatur
    str_chunk(12,4).should == 'fmt '

    # 16  4 <fmt length> (16 Byte)
    int_chunk(16,4).should == 16

    # 20  2 <format tag>
    int_chunk(20,2).should == 1

    # 22  2 <channels>  1 = mono, 2 = stereo
    int_chunk(22,2).should == 1

    # 24  4 <sample rate> Abtastrate pro Sekunde (z.B. 44100)
    int_chunk(24,4).should == 16000

    # 28  4 <bytes/second>  Abtastrate * Block-Align
    int_chunk(28,4).should == 2000

    # 32  2 <block align> <channels> * (<bits/sample> / 8)
    int_chunk(32,2).should == 2

    # 34  2 <bits/sample> 8, 16 oder 24
    int_chunk(34,2).should == 16
  end

  it 'contains data frames' do
    # 36  4 'data'
    str_chunk(36,4).should == 'data'

    # 40  4 <length>
    int_chunk(40,4) == @riff.size - 44

    # 44  <block align>
    # ..

    # check end of file equals end of suggested data length
    @riff.reverse[0...4].should == @riff[44...44+ (@riff.size-44) ].reverse[0...4]
  end
end
