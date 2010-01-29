require 'eventmachine'

module FliteSpeak
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
    def post_init
      @flushed = false
    end

    def flush_input_file
      File.open(TMP_PATH, 'w'){ |f| f.print '' }
      @flushed = true
    end

    def receive_data data
      flush_input_file unless @flushed
      puts "flite spoke: #{data}"
    end

    def unbind
      puts "flite exit: #{get_status.exitstatus}"
    end

    # read text form input file should be saver than passing ' -t ..' via shell
    def self.read_file(filepath)
      EM.popen("/usr/bin/flite -o play -f %s -ps " % [filepath], self)
    end
    #def self.say(str)
    #  EM.popen("/usr/bin/flite -o play -t \"%s\" -ps" % [str], self)
    #end
  end
end

EM.run do
  #EM.start_unix_domain_server '/tmp/flite-speak', FliteQueueListen
  #EM.popen("ruby -e' $stdout.sync = true; gets.to_i.times{ |i| puts i+1; sleep 1 } '", RubyCounter)

  fifo = EM.watch_file(FliteSpeak::TMP_PATH, FliteSpeak)
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

module RubyCounter
 def post_init
   # count up to 5
   send_data "5\n"
 end
 def receive_data data
   puts "ruby sent me: #{data}"
 end
 def unbind
   puts "ruby died with exit status: #{get_status.exitstatus}"
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
