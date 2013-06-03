module TellaPeer
  class Connection < Struct.new(:socket, :remote_ip, :remote_port)
    class << self
      attr_writer :ping_log, :query_log, :connections, :max_connections
      def max_connections
        @max_connections ||= 10
      end
      def ping_log
        @ping_log    ||= {}
      end
      def query_log
        @query_log   ||= {}
      end
      def connections
        @connections ||= {}
      end
      def connection_queue
        @connection_queue ||= []
      end

      def build_from_connections
        [connection_queue.size, max_connections - connections.size].min.times do
          begin
            Timeout::timeout(15) { connect_as_client(*connection_queue.shift).watch }
          rescue
            logger.debug $!
            logger.debug $!.backtrace
          end
        end
      end

      def build(socket, remote_ip, remote_port)
        key = "#{remote_ip}:#{remote_port}"
        if connections[key]
          logger.warn "Tried to reconnect to existing connection #{key}"
        else
          logger.info "Connecting opened to #{key}"
          unless connections.size > max_connections
            connections[key] ||= Connection.new(socket, remote_ip, remote_port)
          else
            socket.close
            logger.info "Connection to #{key} closed due to max connections"
          end
        end
      end

      def ping
        message = TellaPeer::Ping.new
        connections.each do |_, connection|
          connection.send_message(message)
        end
      end

      def query
        message = TellaPeer::Query.new
        connections.each do |_, connection|
          connection.send_message(message)
        end
      end

      def add_potential_connection(ip, port)
        connection_queue << [ip, port]
      end

      def logger
        TellaPeer.logger
      end

      def connect_as_client(remote_ip, remote_port)
        TellaPeer::Connection.build(TCPSocket.open(remote_ip, remote_port), remote_ip, remote_port)
      end
    end

    def initialize(socket, remote_ip, remote_port)
      super(socket, remote_ip, remote_port)
      socket.binmode
    end

    def watch
      Thread.new do
        begin
          until socket.closed? do
            message = TellaPeer::Message.unpack(socket, remote_ip, remote_port)
            read_message(message)
          end
        rescue
          logger.warn $! + $!.backtrace
        ensure
          close_socket
          logger.info "Closed connection to #{key}"
        end
      end
    end

    def close_socket
      socket.close unless socket.closed?
      Connection.connections.delete(key)
    end

    def key
      "#{remote_ip}:#{remote_port}"
    end

    def send_message(message, to: nil)
      to ||= socket
      begin
        to.write(message.pack) if message.transmitable?
      rescue
        logger.debug "Write to #{key} failed"
        close_socket
      end
    end

    def read_ping(message)
      logger.debug "Read Ping #{message.message_id}"
      if ping_log.keys.include? message.message_id
        logger.debug "Remove Ping #{message.message_id} from network"
      else
        ping_log[message.message_id] = socket
        send_message(message.build_reply.increment!)
        flood(message.increment!)
      end
    end

    def read_pong(message)
      logger.debug "Read Pong #{message.message_id}"
      add_potential_connection(message.pretty_ip, message.port)
      if ping_log.keys.include? message.message_id
        send_message(message, to: ping_log[message.message_id])
      else
        logger.debug "Remove Pong #{message.message_id} from network"
      end
    end

    def read_query(message)
      logger.debug "Read Query #{message.message_id}"
      if query_log.keys.include? message.message_id
        logger.debug "Remove Query #{message.message_id} from network"
      else
        query_log[message.message_id] = socket
        send_message(message.build_reply.increment!)
        flood(message.increment!)
      end
    end

    def read_reply(message)
      logger.debug "Read Reply #{message.message_id}"
      message.log
      if query_log.keys.include? message.message_id
        send_message(message, to: query_log[message.message_id])
      else
        logger.debug "Remove Reply #{message.message_id} from network"
      end
    end

    def read_message(message)
      if message.kind_of?    TellaPeer::Ping
        read_ping  message
      elsif message.kind_of? TellaPeer::Pong
        read_pong  message
      elsif message.kind_of? TellaPeer::Query
        read_query message
      elsif message.kind_of? TellaPeer::Reply
        read_reply message
      elsif message.nil?
        # Blank message probably a read error
      else
        logger.warn 'Unknown message: #{message}'
      end
    end

    def flood(message)
      Connection.connections.each do |_, connection|
        send_message(message, to: connection.socket) unless connection == self
      end
    end

    def logger
      TellaPeer.logger
    end

    def ping_log
      Connection.ping_log
    end

    def query_log
      Connection.query_log
    end

    def connection_log
      Connection.connection_log
    end
  end
end