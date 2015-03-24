require 'timeout'
require 'thread'

#
# Monkey Patch timeout support into the IO class
#
class IO
  def each_with_timeout(pid, seconds, sep_string=$/)
    last_update = Time.now

    current_thread = Thread.current
    check_update_thread = Thread.new do
      loop do
        sleep 0.1
        if last_update - Time.now < -seconds
          current_thread.raise Timeout::Error.new('output wait time expired')
        end
      end
    end

    each(sep_string) do |buffer|
      last_update = Time.now
      yield buffer
    end
  rescue Timeout::Error
    Process.kill('SIGKILL', pid)
    raise
  ensure
    check_update_thread.kill
  end
end
