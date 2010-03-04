require 'eventmachine'


class NotifyTimer
  Schedules = []
  attr_accessor :o, :s
  def initialize(options={}, &block)
    @o = { every: 5, priority: 20, msg: 'tick', block: block }.merge(options)
    @s = { count: 0 }
    Schedules << self
  end
  def process_event
    puts '0x%x : %i msg: %s' % [object_id, @s[:count] += 1, @o[:msg]]
    if b = @o[:block]
      b.call(self)
    else
      if h = @o[:handler]
        h.call(self)
      end
    end
  end
  def kill
    @timer.cancel
  end
  def create
    @timer = EM::PeriodicTimer.new(@o[:every], method(:process_event))
  end
end

module FliteSpeakLoop
  Devs = []
  MsgQueue = EM::Queue.new
  State = { lock: false }

  def pop_loop
    #MsgQueue.pop { |v| State[:lock] = true; send_data(v << "\n"); pop_loop }
    MsgQueue.pop { |v| State[:lock] = true; send_data(v << "\n"); pop_loop }
  end

  def post_init
    Devs << [ self ]
    @state ||= {}
    pop_loop
  end
  def send_speak(msg)
    MsgQueue.push msg
  end
  def receive_data data
    #State[:lock] = false
    #puts "#{loop_name} sent me: #{data}"
  end
  def unbind
    puts "loop died: #{get_status.exitstatus}"
  end

  module_function
  def create
    cm = EM.popen(%|ruby -e "$stdout.sync = true; eval File.read('#{__FILE__}').split('__END__').last"|, self)
    (Devs.last << cm)[0]  # [instance, em-popen]
  end
end

module FliteFifo
  # none  /tmp  tmpfs  nodev,nosuid,noexec,nodiratime,size=256M  0 0
  TMP_PATH = '/tmp/flite_fifo'

  def file_modified
    push_file TMP_PATH
  end
  #def file_deleted; puts 'flitefifo deleted'; end
  #def unbind; puts 'fifo unbind'; EM.stop; end

  def push_file(filepath, flush=true)
    return nil if File.size(filepath) == 0

    FliteSpeakLoop::MsgQueue.push File.read(filepath)
    File.open(filepath, 'w'){ |f| f.print '' } if flush
  end
  def self.create(file=TMP_PATH)
    # touch unless exists
    File.open(file, 'w'){ |f| f.print '' } unless File.exists?(file)
    # create watcher
    EM.watch_file(file, self)
  end
end



EM.run do; puts 'starting event loop'
  flite = FliteSpeakLoop.create
  fifo  = FliteFifo.create

  NotifyTimer.new(every: 60*5) do
    flite.send_speak 'time is ' + Time.now.to_s
  end

  #NotifyTimer.new(every: 2) do |t|
  #  flite.send_speak 'tock %i %i' % [t.o[:every], t.s[:count]]
  #end

  NotifyTimer.new(title: 'uptime', every: 60) do |t|
    msg = `uptime`.scan(/(.+?)\:(.+?)\:(.+?) up (.+?)\,/).map{|i|
      [i.last, i[0] + ' hours', i[1] + ' minutes' ].join ' '
    }[0]
    flite.send_speak [t.o[:title], msg].join ': '
  end

  # init eventmachine timers
  NotifyTimer::Schedules.each(&:create)
end


__END__
require 'ffi-flite'; FFI::Flite.init
Voice = { kal: FFI::Flite::Voice.init_kal16 }
loop do
  msg = gets.to_s
  puts 'playing %i words. time: %i' % [msg.size, Time.now.to_i]

  u = FFI::Flite.synth_text(msg, Voice[:kal])
  w = FFI::Flite.utt_wave(u)
  FFI::Flite.play_wave(w)
  FFI::Flite.delete_utterance(u)

  puts 'finish %i words. time: %i' % [msg.size, Time.now.to_i]
end
