# API references:
#
# * http://dev.w3.org/html5/websockets/
# * http://dvcs.w3.org/hg/domcore/raw-file/tip/Overview.html#interface-eventtarget
# * http://dvcs.w3.org/hg/domcore/raw-file/tip/Overview.html#interface-event

require 'uri'
require 'celluloid'
require 'celluloid/autostart'
require 'websocket/driver'

module WebSocks

  class WebSocket
    require File.expand_path('../websocket/api', __FILE__)
    require File.expand_path('../stream', __FILE__)

    def self.determine_url(env)
      scheme = secure_request?(env) ? 'wss:' : 'ws:'
      "#{ scheme }//#{ env['HTTP_HOST'] }#{ env['REQUEST_URI'] }"
    end

    def self.secure_request?(env)
      return true if env['HTTPS'] == 'on'
      return true if env['HTTP_X_FORWARDED_SSL'] == 'on'
      return true if env['HTTP_X_FORWARDED_SCHEME'] == 'https'
      return true if env['HTTP_X_FORWARDED_PROTO'] == 'https'
      return true if env['rack.url_scheme'] == 'https'

      return false
    end

    def self.websocket?(env)
      ::WebSocket::Driver.websocket?(env)
    end

    attr_reader :env
    include API

    def initialize(env, protocols = nil, options = {})
      env['rack.hijack'].call

      @env       = env
      @hijack_io = env['rack.hijack_io']
      @url       = WebSocket.determine_url(@env)
      @driver    = ::WebSocket::Driver.rack(self, :protocols => protocols)
      @stream    = Stream.new(@hijack_io, @driver)

      super(options)

      @driver.start
      @stream.async.listen
    end

    def rack_response
      [ -1, {}, [] ]
    end

  end
end

