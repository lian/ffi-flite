require 'ffi-flite'

FFI::Flite.init
voice = FFI::Flite::Voice.init_kal16


def text_to_audio(text, voice, fileout=nil)
  u = FFI::Flite.synth_text text, voice
  w = FFI::Flite.utt_wave(u)

  if fileout
    FFI::Flite.save_wave_riff(w, fileout)
  else
    FFI::Flite.play_wave(w)
  end

  FFI::Flite.delete_utterance(u)
end



ARGV.select{|f| File.file?(f) }.each do |f|
  write_path = ARGV.include?('-w') ? File.basename(f)+'.riff' : nil

  text = File.read(f)
  text_to_audio(text, voice, write_path)
end
