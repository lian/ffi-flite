## libflite.so via ffi
# % git clone git://github.com/optionalgod/flite.git
# % cd flite; ./configure --enable-shared; make
# % sudo cp build/*/lib/libfl*.so*  /usr/lib

require 'eventmachine'
require 'ffi'

module FFI::Flite
  extend FFI::Library
  ffi_lib 'smixer-sbase.so', '/usr/lib/alsa-lib/smixer/smixer-sbase.so'
  ffi_lib 'libflite.so'

  attach_function :init, :flite_init, [], :int
  attach_function :text_to_speech, :flite_text_to_speech, [:string, :pointer, :string], :float
  attach_function :synth_text, :flite_synth_text, [:string, :pointer], :pointer
  attach_function :utt_wave, [:pointer], :pointer
  attach_function :play_wave, [:pointer], :int
  attach_function :delete_utterance, [:pointer], :int
  attach_function :save_wave_riff, :cst_wave_save_riff, [:pointer, :string], :int

  ffi_lib 'libflite_usenglish.so', 'libflite_cmulex.so'

  module Voice
    extend FFI::Library
    %w[kal kal16 rms slt awb].each do |name|
      ffi_lib 'flite_cmu_us_%s.so' % [name]
      attach_function "init_#{name}".to_sym, "register_cmu_us_#{name}".to_sym, [], :pointer
    end
    #ffi_lib 'flite_cmu_us_kal16.so'
    #attach_function :init_kal16, :register_cmu_us_kal16, [], :pointer
  end
end


__END__
FFI::Flite.init
voice = FFI::Flite::Voice.init_kal16

u = FFI::Flite.synth_text 'test utterance', voice
w = FFI::Flite.utt_wave(u)
# durs = (float)w->num_samples / (float)w-sample_rate

FFI::Flite.play_wave(w)
FFI::Flite.save_wave_riff(w, 'test_utterance.riff')

FFI::Flite.delete_utterance(u)


__END__
EM.run do
  FFI::Flite.init
  voice = FFI::Flite::Voice.init_kal16

  EM::PeriodicTimer.new(5) {
    FFI::Flite.text_to_speech `uptime`, voice, 'play'
  }
end


__END__
extern cst_val *flite_voice_list;
/* Public functions */
int flite_init();
/* General top level functions */
cst_voice *flite_voice_select(const char *name);
float flite_file_to_speech(const char *filename, cst_voice *voice, const char *outtype);
float flite_text_to_speech(const char *text, cst_voice *voice, const char *outtype);
float flite_phones_to_speech(const char *text, cst_voice *voice, const char *outtype);
float flite_ssml_to_speech(const char *filename, cst_voice *voice, const char *outtype);
int flite_voice_add_lex_addenda(cst_voice *v, const cst_string *lexfile);
/* Lower lever user functions */
cst_wave *flite_text_to_wave(const char *text,cst_voice *voice);
cst_utterance *flite_synth_text(const char *text,cst_voice *voice);
cst_utterance *flite_synth_phones(const char *phones,cst_voice *voice);
cst_utterance *flite_do_synth(cst_utterance *u, cst_voice *voice, cst_uttfunc synth);
float flite_process_output(cst_utterance *u, const char *outtype, int append);

