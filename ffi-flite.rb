require 'ffi'

module FFI::Flite
  SPA = $flite_so_path ? File.dirname(__FILE__)+'/../tmp/' : ''

  extend FFI::Library
  ffi_lib [ SPA+'smixer-sbase.so', '/usr/lib/alsa-lib/smixer/smixer-sbase.so']
  ffi_lib [ SPA+'libflite.so' ]

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
      ffi_lib SPA+('flite_cmu_us_%s.so' % [name])
      attach_function "init_#{name}".to_sym, "register_cmu_us_#{name}".to_sym, [], :pointer
    end
  end
end


__END__
EM.run do
  FFI::Flite.init
  voice = FFI::Flite::Voice.init_kal16

  EM::PeriodicTimer.new(5) {
    FFI::Flite.text_to_speech `uptime`, voice, 'play'
  }
end
