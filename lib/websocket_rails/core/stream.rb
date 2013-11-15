module WebsocketRails::Core
  class Stream

    include Celluloid
    include Celluloid::Logger

    def initialize(io, driver)
      @io = io
      @driver = driver
      @ping_id = 0
    end

    def write(data)
      @io.write data
    end

    def close
      @ping_timer.cancel if @ping_timer
      @io.close
      @io = nil
      terminate
    end

    def start_ping_timer(ping)
      @ping_timer = every(ping) do
        @ping_id += 1
        ping(@ping_id.to_s)
      end
    end

    def ping(message = '', &callback)
      @driver.ping(message, &callback)
    end

    def listen
      loop {
        begin
          @driver.parse @io.readpartial(4096)
        rescue => e
          debug "Connection closed: #{e}"
          break
        end
      }
    end

    def write(data)
      @io.write(data)
    rescue => e
      fail if EOFError === e
    end

  end
end
