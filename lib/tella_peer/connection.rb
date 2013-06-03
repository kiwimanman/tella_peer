module TellaPeer
  class Connection < Struct.new(:socket, :remote_ip, :remote_port)
    class << self
      attr_writer :ping_log, :query_log, :connections
      def ping_log
        @ping_log    ||= {}
      end
      def query_log
        @query_log   ||= {}
      end
      def connections
        @connections ||= {}
      end

      def build(socket, remote_ip, remote_port)
        key = "#{remote_ip}:#{remote_port}"
        connections[key] ||= Connection.new(socket, remote_ip, remote_port)
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
          puts $!.backtrace
        ensure
          socket.close unless socket.closed?
          Connection.connectons.delete(key)
          puts "Closed connection to #{key}"
        end
      end
    end

    def key
      "#{remote_ip}:#{remote_port}"
    end

    def send_message(message, to: nil)
      to ||= socket
      begin
        to.write(message.pack) if message.transmitable?
      rescue
        socket.close unless socket.closed?
        Connection.connections.delete(key)
        puts "Closed connection to #{key}"
      end
    end

    def read_message(message)
      if message.kind_of? TellaPeer::Ping
        puts 'Ping'
        if ping_log.keys.include? message.message_id
          # Remove from network
        else
          ping_log[message.message_id] = socket
          send_message(message.build_reply.increment!)
          # Broadcast
        end
      elsif message.kind_of? TellaPeer::Pong
        puts 'Pong'
        if ping_log.keys.include? message.message_id
          send_message(message, to: ping_log[message.message_id])
        else
          # Remove from network
        end
      elsif message.kind_of? TellaPeer::Query
        puts 'Query'
        if query_log.keys.include? message.message_id
          # Remove from network
        else
          query_log[message.message_id] = socket
          send_message(message.build_reply.increment!)
          # Broadcast
        end
      elsif message.kind_of? TellaPeer::Reply
        puts 'Reply'
        if query_log.keys.include? message.message_id
          send_message(message, to: query_log[message.message_id])
        else
          # Remove from network
        end
      elsif message.nil?
        # "Blank message"
      else
        puts 'Unknown message: #{message}'
      end
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

    def self.connect_as_client(remote_ip, remote_port)
      TellaPeer::Connection.build(TCPSocket.open(remote_ip, remote_port), remote_ip, remote_port)
    end
  end
end