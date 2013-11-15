module WebSocks
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
          break if @closed
          @driver.parse @io.readpartial(4096)
        rescue => e
          debug "Connection closed: #{e}"
          break
        end
        sleep 0.1
      }
    end

    #def clean_rack_hijack
    #  @rack_hijack_io_reader.close_connection_after_writing
    #  @rack_hijack_io = @rack_hijack_io_reader = nil
    #end

    #def close_connection
    #  clean_rack_hijack
    #  @connection.close_connection if @connection
    #end

    #def close_connection_after_writing
    #  clean_rack_hijack
    #  @connection.close_connection_after_writing if @connection
    #end

    def write(data)
      @io.write(data)
    rescue => e
      fail if EOFError === e
    end

  end
end
