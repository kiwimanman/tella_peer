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
  attr_writer :logger
  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
