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

  def post_init
    Devs << [self]
    @state ||= {}
  end
  def send_speak(msg)
    send_data(msg << "\n")
  end
  def receive_data data
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



require 'eventmachine'
EM.run do; puts 'starting event loop'
  flite = FliteSpeakLoop.create

  NotifyTimer.new(every: 60*5) do
    flite.send_speak 'time is ' + Time.now.to_s
  end

  #NotifyTimer.new(every: 2) do |t|
  #  flite.send_speak 'tock %i %i' % [t.o[:every], t.c[:count]]
  #end

  NotifyTimer.new(every: 60) do |t|
    #msg = [ 'uptime', `uptime`.scan(/up (.+?)\,/)[0][0] ].join(' ')
    msg = [ 'uptime', `uptime`.split(',').first].join(' ')
    flite.send_speak msg
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
