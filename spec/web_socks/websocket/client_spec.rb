# encoding=utf-8

require "spec_helper"
require "socket"

IS_JRUBY = (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby')

module WebSocketSteps
  def server(port, backend, secure)
    @server = EchoServer.new
    @server.listen(port, backend, secure)
  end

  def stop
    @server.stop
  end

  def open_socket(url, protocols)
    done = false

    resume = lambda do |open|
      unless done
        done = true
        @open = open
      end
    end

    @ws = Faye::WebSocket::Client.new(url, protocols)

    @ws.on(:open) { |e| resume.call(true) }
    @ws.onclose = lambda { |e| resume.call(false) }
    @ws.onerror = lambda { raise "connection error" }
  end

  def close_socket
    @ws.onclose = lambda do |e|
      @open = false
    end
    @ws.close
  end

  def check_open
    @open.should == true
  end

  def check_closed
    @open.should == false
  end

  def check_protocol(protocol)
    @ws.protocol.should == protocol
  end

  def listen_for_message
    @ws.add_event_listener('message', lambda { |e| @message = e.data })
  end

  def send_message(message)
    @ws.send(message)
  end

  def check_response(message)
    @message.should == message
  end

  def check_no_response
    @message.should == nil
  end
end

describe WebSocks::WebSocket do
  around(:each) do |example|
    Celluloid.boot
    EM.run { example.run; EM.add_timer(1) { EM.stop } }
    Celluloid.shutdown
  end

  include WebSocketSteps

  let(:port) { 4180 }

  let(:protocols)      { ["foo", "echo"]          }
  let(:plain_text_url) { "ws://0.0.0.0:#{port}/"  }
  let(:wrong_url)      { "ws://0.0.0.0:9999/"     }
  let(:secure_url)     { "wss://0.0.0.0:#{port}/" }

  shared_examples_for "socket client" do
    it "can open a connection" do
      #open_socket(socket_url, protocols)
      server port, :puma, false
      @ws = Faye::WebSocket::Client.new(url, protocols)

      test = nil
      @ws.on(:open) { |e| test = true }
      @ws.onclose = lambda { |e| resume.call(false) }
      @ws.onerror = lambda { raise "wtf" }
      test.should == true
      #check_open
      @ws.protocol.should == "echo"
    end

    it "cannot open a connection to the wrong host" do
      open_socket(blocked_url, protocols)
      check_closed
    end

    it "can close the connection" do
      open_socket(socket_url, protocols)
      close_socket
      check_closed
    end

    describe "in the OPEN state" do
      before { open_socket(socket_url, protocols) }

      it "can send and receive messages" do
        listen_for_message
        send_message "I expect this to be echoed"
        check_response "I expect this to be echoed"
      end

      it "sends numbers as strings" do
        listen_for_message
        send_message 13
        check_response "13"
      end
    end

    describe "in the CLOSED state" do
      before do
        open_socket(socket_url, protocols)
        close_socket
      end

      it "cannot send and receive messages" do
        listen_for_message
        send_message "I expect this to be echoed"
        check_no_response
      end
    end
  end

  describe "with a Puma server" do
    let(:socket_url)  { plain_text_url }
    let(:blocked_url) { wrong_url }

    #before { server port, :puma, false }
    it "can open a connection" do
      server port, :puma, false
      open_socket(socket_url, protocols)
      check_open
      check_protocol("echo")
      stop
    end

    it_should_behave_like "socket client"
  end

  #describe "with a plain-text Thin server" do
  #  next if IS_JRUBY

  #  let(:socket_url)  { plain_text_url }
  #  let(:blocked_url) { secure_url }

  #  before { server port, :thin, false }
  #  after  { stop }

  #  it_should_behave_like "socket client"
  #end

  #describe "with a secure Thin server" do
  #  next if IS_JRUBY

  #  let(:socket_url)  { secure_url }
  #  let(:blocked_url) { plain_text_url }

  #  before { server port, :thin, true }
  #  after  { stop }

  #  it_should_behave_like "socket client"
  #end
end

