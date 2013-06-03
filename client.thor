#!/usr/bin/env ruby

require 'tella_peer'

class Client < Thor

  desc "start", "Starts the P2P client by connecting to a seed"
  method_option :port,  :aliases => "-p",                    :desc => "Port to run our server on"
  method_option :ttl,   :aliases => "-t",                    :desc => "Default ttl on new messages"
  method_option :local, :aliases => "-l", :type => :boolean, :desc => "Run the server on localhost"
  method_option :reply, :aliases => "-r",                    :desc => "String to serve in replys"

  def start(seed = "128.208.2.88:5002")
    process_options

    begin
      seed_ip, seed_port = seed.split(':')
      Timeout::timeout(15) { TellaPeer::Connection.connect_as_client(seed_ip, seed_port) }.watch
      TellaPeer.logger.info "Connected to seed"
    rescue
      puts $!
    end

    TellaPeer.start_outbound_sceduler
    TellaPeer.start_connection_builder

    Socket.tcp_server_loop(TellaPeer::Message.port) {|sock, client_addrinfo|
      TellaPeer::Connection.build(
        sock,
        client_addrinfo.ip_address,
        client_addrinfo.ip_port)
      .watch
    }
  end

  no_commands do
    def process_options
      TellaPeer::Message.port  = options[:port].to_i if options[:port]
      TellaPeer::Message.ttl   = options[:ttl].to_i  if options[:ttl]
      TellaPeer::Message.ip    = open( 'http://jsonip.com/ ' ){ |s| JSON::parse( s.string())['ip'] }.split('.') unless options[:local]
      TellaPeer::Message.text  = options[:reply] || options[:port]
    end
  end
end