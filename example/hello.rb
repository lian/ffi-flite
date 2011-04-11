require 'ffi-flite'

FFI::Flite.init
voice = FFI::Flite::Voice.init_kal16


text = 'ruby version - ' + RUBY_VERSION


u = FFI::Flite.synth_text text, voice
w = FFI::Flite.utt_wave(u)
    FFI::Flite.play_wave(w)
    #FFI::Flite.save_wave_riff(w, filename)
    FFI::Flite.delete_utterance(u)

# OR just:

FFI::Flite.text_to_speech text, voice, 'play'
