require 'eventmachine'
require 'fileutils'

module FliteSpeak
  # none  /tmp  tmpfs  nodev,nosuid,noexec,nodiratime,size=256M  0 0
  TMP_PATH = '/tmp/flite_fifo'
  F_FILE_BIN = "/usr/bin/flite -o play -f %s -ps "
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
end


EM.run do
  flite_fifo = EM.watch_file(FliteSpeak::TMP_PATH, FliteSpeak)
end

