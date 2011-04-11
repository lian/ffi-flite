require 'ffi'

module FFI::Flite
  extend FFI::Library
  @ffi_lib_flags = FFI::DynamicLibrary::RTLD_LAZY | FFI::DynamicLibrary::RTLD_GLOBAL
  ffi_lib [ 'smixer-sbase', '/usr/lib/alsa-lib/smixer/smixer-sbase.so'], [ 'flite' ]

  attach_function :init, :flite_init, [], :int
  attach_function :text_to_speech, :flite_text_to_speech, [:string, :pointer, :string], :float
  attach_function :synth_text, :flite_synth_text, [:string, :pointer], :pointer
  attach_function :utt_wave, [:pointer], :pointer
  attach_function :play_wave, [:pointer], :int
  attach_function :delete_utterance, [:pointer], :int
  attach_function :save_wave_riff, :cst_wave_save_riff, [:pointer, :string], :int

  ffi_lib 'flite_usenglish'

  module Voice
    extend FFI::Library
    @ffi_lib_flags = FFI::DynamicLibrary::RTLD_LAZY | FFI::DynamicLibrary::RTLD_GLOBAL
    ffi_lib 'flite_cmulex'

    %w[kal kal16 rms slt awb].each do |name|
      ffi_lib ('flite_cmu_us_%s' % [name])
      attach_function "init_#{name}".to_sym, "register_cmu_us_#{name}".to_sym, [], :pointer
    end
  end
end


if $0 == __FILE__

  FFI::Flite.init
  voice = FFI::Flite::Voice.init_kal16
  FFI::Flite.text_to_speech `uptime`, voice, 'play'

end
