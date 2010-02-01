require 'bacon'; Bacon.summary_on_exit

describe 'Riff Format' do
  @riff = File.read('test_utterance.riff').bytes.to_a

  it 'contains riff header' do
    # file size
    @riff.size.should >= 48  # == 41156 for test_utterance.riff

    # Offset RIFF-Header
    # 0 4 'RIFF'
    # 4 4 <Dateigröße - 8>
    # 8 4 'WAVE'
    @riff[0...4].map(&:chr).join.should == 'RIFF'
    @riff[4...8].reverse.map{|i|'%x'%[i]}.join.to_i(16).should == @riff.size - 8
    @riff[8...12].map(&:chr).join.should == 'WAVE'
  end

  it 'contains data frames' do
    # Offset Data
    # 36  4 'data'
    # 40  4 <length>
    # 44  <block align> der erste Abtastwert
    @riff[36...36+4].map(&:chr).join == 'data'
    @riff[40...40+4].reverse.map{|i|'%x'%[i]}.join.to_i(16).should == @riff.size - 44
    @riff[44...44+ (@riff.size-44) ].reverse[0...4].should == @riff.reverse[0...4]
  end
end
