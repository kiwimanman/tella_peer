#!/usr/bin/env ruby

require 'tella_peer'

require 'json'
require 'open-uri'
TellaPeer::Message.ip = open( 'http://jsonip.com/ ' ){ |s| JSON::parse( s.string())['ip'] }.split('.')

class Client < Thor

  desc "start", "Starts the P2P client by connecting to a seed"
  method_option :port, :aliases => "-p", :desc => "Port to run our server on"
  def start(seed = "128.208.2.88:5002")
    debugger
    TellaPeer::Message.port = options[:port]

    ping_log = {} # Vash.new
    query_log = {}

    Socket.tcp_server_loop(TellaPeer::Message.ip.join('.'),
                           TellaPeer::Message.port) {|sock, client_addrinfo|
      sock.binmode
      #Thread.new {
        begin
          debugger
          message = TellaPeer::Message.unpack(sock, client_addrinfo.ip, client_addrinfo.port)
        ensure
          sock.close
        end
        puts 
      #}
    }

    seed_ip, seed_port = seed.split(':')

    s = TCPSocket.open(seed_ip, seed_port)
    s.binmode

    s.write TellaPeer::Ping.new.pack

    loop do
      message = TellaPeer::Message.unpack(s, seed_ip, seed_port)
      read_message(message)
    end

    s.close
  end

  def send_message(message, to: nil)
    message.increment!
    s.write message if message.transmitable?
  end

  def read_message(message, s)
    if message.kind_of? TellaPeer::Ping
      puts 'Ping'
      if ping_log.keys.include? message.message_id
        # Remove from network
      else
        ping_log[message.message_id] = s
        debugger
        send_message(message.build_reply, to: s)
        # Broadcast
      end
    elsif message.kind_of? TellaPeer::Pong
      puts 'Pong'
      if ping_log.keys.include? message.message_id
        socket = ping_log[message.message_id]
        send_message(message, to: socket)
      else
        # Remove from network
      end
    elsif message.kind_of? TellaPeer::Query
      puts 'Query'
      if query_log.keys.include? message.message_id
        # Remove from network
      else
        query_log[message.message_id] = s
        send_message(message.build_reply, to: s)
        # Broadcast
      end
    elsif message.kind_of? TellaPeer::Reply
      puts 'Reply'
      if query_log.keys.include? message.message_id
        socket = query_log[message.message_id]
        send_message(message, to: socket)
      else
        # Remove from network
      end
    else
      puts 'Unknown message: #{message}'
    end
  end
end