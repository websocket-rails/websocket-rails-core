require "timers"

module WebsocketRails::Core
  class Stream

    def initialize(io, driver)
      @io = io
      @driver = driver
      @ping_id = 0
      @ping_timer = nil
    end

    def write(data)
      @io.write data
    end

    def close
      if @timer_thread
        @ping_timer.cancel
        @timer_thread.terminate
        @timer_thread = nil
      end

      @listen.terminate
      @listen = nil

      @io.close
      @io = nil
    end

    def start_ping_timer(ping)
      @timer_thread = Thread.new {
        @ping_timer = every(ping) do
          @ping_id += 1
          ping(@ping_id.to_s)
        end
      }
    end

    def ping(message = '', &callback)
      @driver.ping(message, &callback)
    end

    def listen
      @listen = Thread.new {
        loop do
          begin
            @driver.parse @io.readpartial(4096)
          rescue => e
            debug "Connection closed: #{e}"
            break
          end
        end
      }
    end

    def write(data)
      @io.write(data)
    rescue => e
      fail if EOFError === e
    end

    private

    def every(seconds, &block)
      timers.every(seconds, &block)
    end

    def timers
      @timers ||= Timers.new
    end

  end
end
