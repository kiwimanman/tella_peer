#!/usr/bin/env ruby

require 'tella_peer'

require 'json'
require 'open-uri'
TellaPeer::Message.ip = open( 'http://jsonip.com/ ' ){ |s| JSON::parse( s.string())['ip'] }.split('.')

class Client < Thor

  desc "start", "Starts the P2P client by connecting to a seed"
  method_option :port, :aliases => "-p", :desc => "Port to run our server on"
  method_option :ttl,  :aliases => "-t", :desc => "Default ttl on new messages"
  def start(seed = "128.208.2.88:5002")
    TellaPeer::Message.port = options[:port].to_i if options[:port]
    TellaPeer::Message.ttl  = options[:ttl].to_i  if options[:ttl]
    
    ping_log = {} # Vash.new
    query_log = {}

    t = Thread.new {
      seed_ip, seed_port = seed.split(':')

      s = nil
      begin
        Timeout::timeout(15) { s = TCPSocket.open(seed_ip, seed_port) }
        s.binmode
        s.write TellaPeer::Ping.new.pack
        loop do
          message = TellaPeer::Message.unpack(s, seed_ip, seed_port)
          read_message(message)
        end
      rescue
        $stdout.puts $!
      ensure
        s.close if s
      end
    }

    t.join

    Socket.tcp_server_loop(TellaPeer::Message.port) {|sock, client_addrinfo|
      sock.binmode
      Thread.new {
        begin
          loop do
            debugger
            message = TellaPeer::Message.unpack(sock, client_addrinfo.ip, client_addrinfo.port)
            read_message(message)
          end
        ensure
          sock.close
        end
        $stdout.puts 
      }
    }

  end
  no_commands do
    def send_message(message, to: nil)
      message.increment!
      s.write message if message.transmitable?
    end

    def read_message(message, s)
      if message.kind_of? TellaPeer::Ping
        $stdout.puts 'Ping'
        if ping_log.keys.include? message.message_id
          # Remove from network
        else
          ping_log[message.message_id] = s
          debugger
          send_message(message.build_reply, to: s)
          # Broadcast
        end
      elsif message.kind_of? TellaPeer::Pong
        $stdout.puts 'Pong'
        if ping_log.keys.include? message.message_id
          socket = ping_log[message.message_id]
          send_message(message, to: socket)
        else
          # Remove from network
        end
      elsif message.kind_of? TellaPeer::Query
        $stdout.puts 'Query'
        if query_log.keys.include? message.message_id
          # Remove from network
        else
          query_log[message.message_id] = s
          send_message(message.build_reply, to: s)
          # Broadcast
        end
      elsif message.kind_of? TellaPeer::Reply
        $stdout.puts 'Reply'
        if query_log.keys.include? message.message_id
          socket = query_log[message.message_id]
          send_message(message, to: socket)
        else
          # Remove from network
        end
      else
        $stdout.puts 'Unknown message: #{message}'
      end
    end
  end
end