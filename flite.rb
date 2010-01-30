require 'eventmachine'
require 'fileutils'

module FliteSpeak
  # none  /tmp  tmpfs  nodev,nosuid,noexec,nodiratime,size=256M  0 0
  TMP_PATH = '/tmp/flite_fifo'
  F_FILE_BIN = "/usr/bin/flite -o play -f %s -ps --setf duration_stretch=1.2 --setf int_f0_target_mean=90"
  F_STR_BIN  = "/usr/bin/flite -o play -t \"%s\" -ps "
  MsgQueue = EM::Queue.new


  def file_modified
    push_file TMP_PATH
  end

  def file_deleted
    puts 'fifo deleted'
  end

  def unbind
    puts 'fifo unbind'; EM.stop
  end


  def push_file(filepath, flush=true)
    return nil if File.size(filepath) == 0

    MsgQueue.push File.read(filepath)
    File.open(filepath, 'w'){ |f| f.print '' } if flush

    process_queue( filepath + '.pb' )
  end

  def process_queue(path, c=1)
    #p '--process_queue %s, %i' % [path, c]

    if SpeakDev::State[:lock] == true
      EM::Timer.new(0.5){process_queue(path, c+1)}
    else
      MsgQueue.pop do |v|  log_input(v)
        # write flite input file
        File.open(path, 'w'){|f| f.print v }
        # exec flite
        EM.popen(F_FILE_BIN % [path], SpeakDev)
        #EM::Timer.new(0.5){process_queue(path, c+1)} unless MsgQueue.empty?
      end
    end
  end


  module SpeakDev
    State =  { :lock => false }
    def receive_data data
      puts "flite spoke: #{data}"
    end
    def post_init
      State[:lock] = true
    end
    def unbind
      State[:lock] = false
      State[:exitcode] = get_status.exitstatus
    end
  end

  LOG_TEMPLATE = "\n--> Process Event: %s  %i\nflite input: %s\n"
  def log_input(msg)
    print LOG_TEMPLATE % ['mem', Time.now.to_i, msg.inspect]
  end

  #def self.from_string(str)
  #  EM.popen(F_STR_BIN % [path], self)
  #end
  def self.create(file=TMP_PATH)
    # touch unless exists
    File.open(file, 'w'){ |f| f.print '' } unless File.exists?(file)
    # create watcher
    EM.watch_file(file, self)
  end
end

if $0 == __FILE__
  if ARGV.include? '--daemon'
    fork do
      #if user = ARGV.select{|i| i.match(/^--user=/) }.first
      #  require 'etc';  Process.uid = Etc.getpwnam(user.split('=').last).uid
      #end
      trap(:HUP){ 'terminal disconnected' }
      rd, @wr = IO.pipe
      $oldstdout=$stdout.dup;$stdout.reopen(@wr)

      EM.run do
        flite_fifo = FliteSpeak.create
        EM::PeriodicTimer.new(10) { @wr.flush }
      end

      $stdout.reopen($oldstdout)
      puts "DAEMON: file: %s pid:%i   exit 0" % [__FILE__, Process.pid]
    end
  else

    EM.run do
      flite_fifo = FliteSpeak.create
    end
  end
end

