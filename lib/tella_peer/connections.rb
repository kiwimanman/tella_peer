module TellaPeer
  class Connections
    class << self
      attr_writer :ping_log, :query_log, :reply_log, :connections, :max_connections
      attr_accessor :seed

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

      def reply_log
        @reply_log ||= {}
      end

      def close_connection(key)
        connections.delete(key)
      end

      def build_from_connections
        connection_queue << seed if connection_queue.empty? && connections.empty?
        [connection_queue.size, max_connections - connections.size].min.times do
          begin
            candidate = nil
            loop do
              break if connection_queue.empty?
              candidate = connection_queue.shift
              break if !connections.keys.include? candidate.join(':')
              candidate = nil
            end
            logger.debug "Connecting to #{candidate}"
            Timeout::timeout(15) { connect_as_client(*candidate).watch } if candidate
          rescue
            logger.debug "Unable to connect to #{candidate}"
            logger.debug $!
          end
        end
      end

      def build(socket, remote_ip, remote_port, direction = :inbound)
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
        connections[key]
      end

      def ping
        flood(Ping.new)
      end

      def query
        flood(Query.new)
      end

      def flood(message, except_to: nil)
        connections.each do |_, connection|
          connection.send_message(message) unless connection == except_to
        end
      end

      def seen_ping?(message_id, from: nil)
        if ping_log.keys.include? message_id
          ping_log[message_id]
        else
          ping_log[message_id] = from if from
          false
        end
      end

      def seen_query?(message_id, from: nil)
        if query_log.keys.include? message_id
          query_log[message_id]
        else
          query_log[message_id] = from if from
          false
        end
      end

      def store_reply(message)
        key = message.connection_key
        connection = connections[key]
        connection.text = message.text if connection
        
        unless reply_log[key] && reply_log[key] == message.text
          logger.info "#{key} replied with #{message.text}"
        end

        reply_log[key] = message.text
      end

      def add_potential_connection(ip, port)
        connection_queue << [ip, port]
      end

      def logger
        TellaPeer.logger
      end

      def connect_as_client(remote_ip, remote_port)
        build(TCPSocket.open(remote_ip, remote_port), remote_ip, remote_port, :outbound)
      end
    end
  end
end