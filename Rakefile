
desc 'load and build shared flite'
task :build_flite do
  tmp = File.dirname(__FILE__) + '/tmp'
  install_dir = tmp #'/usr/lib'
  FileUtils.mkdir_p tmp

  Dir.chdir(tmp) do
    # fetch
    run "git clone git://github.com/optionalgod/flite.git" unless File.exists?('flite/.git/config')

    # configure & build
    Dir.chdir(tmp+'/flite') do
      run "./configure --enable-shared; make"
    end
    
    # install
    run "sudo cp flite/build/*/lib/libfl*.so*  #{install_dir}"
  end
end
