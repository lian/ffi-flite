require 'ffi'
#require 'eventmachine'

module FFI::Library
  def ffi_lib_global(*names)
    ffi_libs = names.map do |name|
      if name == FFI::CURRENT_PROCESS
        FFI::DynamicLibrary.open(nil, FFI::DynamicLibrary::RTLD_LAZY | FFI::DynamicLibrary::RTLD_LOCAL)
      else
        libnames = (name.is_a?(::Array) ? name : [ name ]).map { |n| [ n, FFI.map_library_name(n) ].uniq }.flatten.compact
        lib = nil
        errors = {}

        libnames.each do |libname|
          begin
            lib = FFI::DynamicLibrary.open(libname, FFI::DynamicLibrary::RTLD_LAZY | FFI::DynamicLibrary::RTLD_GLOBAL)
            break if lib
          rescue Exception => ex
            errors[libname] = ex
          end
        end

        if lib.nil?
          raise LoadError.new(errors.values.join('. '))
        end

        # return the found lib
        lib
      end
    end
    @ffi_libs = ffi_libs
  end
end

module FFI::Flite
  extend FFI::Library
  SPA = $flite_so_path ? File.dirname(__FILE__)+'/../tmp/' : ''

  ffi_lib_global [ SPA+'smixer-sbase.so', '/usr/lib/alsa-lib/smixer/smixer-sbase.so']
  ffi_lib_global SPA+'libflite'

  attach_function :init, :flite_init, [], :int
  attach_function :text_to_speech, :flite_text_to_speech, [:string, :pointer, :string], :float
  attach_function :synth_text, :flite_synth_text, [:string, :pointer], :pointer
  attach_function :utt_wave, [:pointer], :pointer
  attach_function :play_wave, [:pointer], :int
  attach_function :delete_utterance, [:pointer], :int
  attach_function :save_wave_riff, :cst_wave_save_riff, [:pointer, :string], :int


  ffi_lib_global SPA+'libflite_usenglish'

  module Voice
    extend FFI::Library
    ffi_lib_global SPA+'libflite_cmulex'

    %w[kal kal16 rms slt awb].each do |name|
      ffi_lib_global SPA+('libflite_cmu_us_%s.so' % [name])
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
