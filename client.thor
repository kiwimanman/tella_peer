#!/usr/bin/env ruby

require 'tella_peer'

class Client < Thor

  desc "start", "Starts the P2P client by connecting to a seed"
  method_option :port,  :aliases => "-p",                    :desc => "Port to run our server on"
  method_option :ttl,   :aliases => "-t",                    :desc => "Default ttl on new messages"
  method_option :local, :aliases => "-l", :type => :boolean, :desc => "Run the server on localhost"
  method_option :reply, :aliases => "-r",                    :desc => "String to serve in replys"
  method_option :log_level,                                  :desc => "Log Level"
  method_option :status_page,             :type => :boolean, :desc => "Run the status page on 4567"

  def start(seed = "128.208.2.88:5002")
    process_options(seed)

    require 'tella_peer/status_page'

    TellaPeer.start_outbound_sceduler
    TellaPeer.start_connection_builder

    Socket.tcp_server_loop(TellaPeer::Message.port) {|sock, client_addrinfo|
      c = TellaPeer::Connections.build(
        sock,
        client_addrinfo.ip_address,
        client_addrinfo.ip_port)
      .
      c.watch if c
    }
  end

  no_commands do
    def process_options(seed)
      TellaPeer::Message.port  = options[:port].to_i if options[:port]
      TellaPeer::Message.ttl   = options[:ttl].to_i  if options[:ttl]
      TellaPeer::Message.ip    = open( 'http://jsonip.com/ ' ){ |s| JSON::parse( s.string())['ip'] }.split('.') unless options[:local]
      TellaPeer::Message.text  = options[:reply] || options[:port]

      seed_ip, seed_port = seed.split(':')
      TellaPeer::Connections.seed = [seed_ip, seed_port]
      TellaPeer::Connections.seed_connections
      TellaPeer::Connections.start_time

      TellaPeer.logger.level = Kernel.const_get("Logger::#{options[:log_level]}") if options[:log_level]

      TellaPeer.logger.info { "Starting on #{TellaPeer::Message.ip.join('.')}:#{TellaPeer::Message.port}" }
      TellaPeer.logger.info { "Serving: #{TellaPeer::Message.text}" }
      TellaPeer.logger.info { "With ttl: #{TellaPeer::Message.ttl}" }
      TellaPeer.logger.info { "Using seed: #{seed}" }
    end
  end
end