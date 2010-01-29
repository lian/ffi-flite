require 'eventmachine'
require 'fileutils'

module FliteSpeak
  # none  /tmp  tmpfs  nodev,nosuid,noexec,nodiratime,size=256M  0 0
  TMP_PATH = '/tmp/flite_fifo'

  def file_modified
    SpeakDev.read_file(TMP_PATH) unless File.size(TMP_PATH) == 0
  end

  def file_deleted
    puts 'fifo deleted'
  end

  def unbind
    puts 'fifo unbind'; EM.stop
  end

  module SpeakDev
    F_FILE_BIN = "/usr/bin/flite -o play -f %s -ps "
    F_STR_BIN  = "/usr/bin/flite -o play -t \"%s\" -ps"
    LOG_TEMPLATE = "\n--> Process Event: %s  %i\nflite input: %s\n"

    def receive_data data
      puts "flite spoke: #{data}"
    end

    def unbind
      #puts "flite exit: #{get_status.exitstatus}"
    end

    def self.flush_input_file(path)
      File.open(path, 'w'){ |f| f.print '' }
    end

    def self.log_input(path)
      print LOG_TEMPLATE % [path, Time.now.to_i, File.read(path).inspect]
    end

    def self.read_file(filepath, flush=true)
      if flush
        path = filepath + '.pb'
        FileUtils.cp filepath, path
        flush_input_file(filepath)
      else
        path = filepath
      end

      log_input(path)
      #p(F_FILE_BIN % [path])
      EM.popen(F_FILE_BIN % [path], self)
    end

    def self.from_string(str)
      EM.popen(F_STR_BIN % [path], self)
    end
  end
end

EM.run do
  #EM.start_unix_domain_server '/tmp/flite-speak', FliteQueueListen

  flite_watch = EM.watch_file(FliteSpeak::TMP_PATH, FliteSpeak)
end



__END__
module FliteQueueListen
  MsgQueue = EM::Queue.new
  def post_init
    puts "-- someone connected to the echo server!"
  end

  def receive_data data
    send_data ">>>you sent: #{data}"
    MsgQueue.push data
    close_connection if data =~ /quit/i
  end

  def unbind
    puts "-- someone disconnected from the echo server!"
  end
end


module FifoFile
  TMP_PATH = '/tmp/flite_fifo'
  MsgQueue = EM::Queue.new

  File.open(TMP_PATH, 'w'){ |f| f.print '' }

  def self.fifo_read
    file = File.read(TMP_PATH)
    #p file
    unless file.empty?
      puts 'read and flushing fifo..'
      File.open(TMP_PATH, 'w'){ |f| f.print '' }
      file.split("\n").each{|msg| MsgQueue.push msg }
    end
  end
  
  def file_modified
    if res = FifoFile.fifo_read
      res.each do |msg|
        p msg;  EM.stop if msg == ':,quit'

        # speak it
        FliteSpeaker.say(msg)
      end
    end
  end

  def file_deleted
    puts 'fifo deleted'
  end
  def unbind
    puts 'fifo unbind'
    EM.stop
  end
end
