class NotifyTimer
  Schedules = []
  def initialize(options={})
    @o = { every: 5, priority: 20, msg: 'tick' }.merge(options)
    @s = { count: 0 }
    Schedules << self
  end
  def process_event
    puts 'process 0x%x : %i msg: %s' % [object_id, @s[:count] += 1, @o[:msg]]
  end
  def kill
    @timer.cancel
  end
  def create
    @timer = EM::PeriodicTimer.new(@o[:every], method(:process_event))
  end
end

module FliteSpeakLoop
  def post_init
   # count up to 5
   # send_data "5\n"
   send_data "hello there!\n"
  end

  def receive_data data
   puts "#{loop_name} sent me: #{data}"
  end

  def unbind
    puts "#{loop_name} loop died with exit status: #{get_status.exitstatus}"
  end

  def loop_name; '%s:%i' % [self.class.name, object_id]; end

  module_function
  def create
    EM.popen(%|ruby -e "$stdout.sync = true; eval File.read('#{__FILE__}').split('__END__').last"|, self)
  end
end


require 'eventmachine'
EM.run do; puts 'starting event loop'

  # run speaker loop
  FliteSpeakLoop.create
end


__END__
# here starts the popen process
class NotifyTimer
  Schedules = []
  def initialize(options={})
    @o = { every: 5, priority: 20, msg: 'tick' }.merge(options)
    @s = { count: 0 }
    Schedules << self
  end
  def process_event
    puts 'playing %i words. time: %i' % [@o[:msg].size, Time.now.to_i]
    #puts 'process 0x%x : %i msg: %s' % [object_id, @s[:count] += 1, @o[:msg]]
    u = FFI::Flite.synth_text(@o[:msg], Voice[:kal])
    w = FFI::Flite.utt_wave(u)
    FFI::Flite.play_wave(w)
    FFI::Flite.delete_utterance(u)
    puts 'finish %i words. time: %i' % [@o[:msg].size, Time.now.to_i]
  end
  def kill
    @timer.cancel
  end
  def create
    @timer = EM::PeriodicTimer.new(@o[:every], method(:process_event))
  end
end

require 'eventmachine'; EM.run do; puts 'starting flite speaker loop'
  require 'ffi-flite'; FFI::Flite.init
  Voice = { kal: FFI::Flite::Voice.init_kal16 }

  NotifyTimer.new
  NotifyTimer.new(every: 2, msg: 'tock')
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
