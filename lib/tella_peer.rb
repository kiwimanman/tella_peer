require 'socket'
require 'ruby-debug'
require "tella_peer/version"
require 'tella_peer/message_types'
require 'tella_peer/message'
require 'tella_peer/ping'
require 'tella_peer/pong'
require 'tella_peer/query'
require 'tella_peer/reply'
require 'tella_peer/connection'

require 'json'
require 'open-uri'

require 'logger'

module TellaPeer
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.start_outbound_sceduler
    Thread.new {
      begin
        loop do
          logger.debug 'Send Ping'
          Connection.ping
          sleep 5
          logger.debug 'Send Query'
          Connection.query
          sleep 5
        end
      rescue
        logger.error "Outbound sceduler crashed"
        logger.error $!
        logger.error $!.backtrace
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
          Connection.build_from_connections
          sleep 5
        end
      rescue
        logger.error "Connection builder crashed"
        logger.error $!
        logger.error $!.backtrace
      ensure
        logger.warn "Connection builder finished"
      end
    }
  end
end
