require 'socket'
require 'ruby-debug'
require "tella_peer/version"
require 'tella_peer/message_types'
require 'tella_peer/message'
require 'tella_peer/ping'
require 'tella_peer/pong'
require 'tella_peer/query'
require 'tella_peer/reply'
require 'tella_peer/connections'
require 'tella_peer/connection'

require 'json'
require 'open-uri'

require 'logger'

module TellaPeer
  def self.logger
    if @logger 
      @logger
    else
      @logger = Logger.new(STDOUT)
      @logger
    end
  end

  def self.start_outbound_sceduler
    Thread.new {
      begin
        count = 0
        loop do
          logger.debug 'Send Ping'
          Connections.ping
          sleep 5
          logger.debug 'Send Query'
          Connections.query
          sleep 5
          if count % 100 == 0
            Connections.clear_logs
            Message.find_public_ip
          end
          count += 1
        end
      rescue
        logger.error "Outbound sceduler crashed"
        logger.error $!
      ensure
        logger.warn "Outbound sceduler finished"
      end
    }
  end

  def self.start_connection_builder
    Thread.new {
      begin
        loop do
          logger.debug 'Building client connections'
          Connections.build_from_connections
          sleep 5
        end
      rescue
        logger.error "Connection builder crashed"
        logger.error $!
      ensure
        logger.warn "Connection builder finished"
      end
    }
  end
end
