module TellaPeer
  class Connection < Struct.new(:socket, :remote_ip, :remote_port, :direction)
    attr_accessor :start_time, :text

    attr_accessor :last_sent, :last_read

    def initialize(socket, remote_ip, remote_port, direction)
      super(socket, remote_ip, remote_port, direction)
      socket.binmode
    end

    def watch
      Thread.new do
        self.start_time = Time.now

        begin
          until socket.closed? do
            message = TellaPeer::Message.unpack(socket, remote_ip, remote_port)
            read_message(message)
          end
        rescue
          logger.debug $!
        ensure
          close_socket
          logger.info "Closed connection to #{key}"
        end
      end
    end

    def close_socket
      socket.close unless socket.closed?
      Connections.close_connection(key)
    end

    def key
      "#{remote_ip}:#{remote_port}"
    end

    def send_message(message, increment: false)
      to ||= socket
      begin
        message.increment! if increment
        if message.transmitable?
          to.write(message.pack) 
          Connections.count_message(message.type, :out)
          self.last_sent = message
        end
      rescue
        logger.debug "Write to #{key} failed -- #{$!.message}"
        logger.debug $!.backtrace
        close_socket
      end
    end

    def read_ping(message)
      if Connections.seen_ping?(message.message_id, from: self)
        no_op(message)
      else
        send_message(message.build_reply)
        Connections.flood(message.increment!, except_to: self)
      end
    end

    def read_pong(message)
      Connections.add_potential_connection(message.pretty_ip, message.port)
      if connection = Connections.seen_ping?(message.message_id)
        connection.send_message(message)
      else
        no_op(message)
      end
    end

    def read_query(message)
      if Connections.seen_query?(message.message_id, from: self)
        no_op(message)
      else
        send_message(message.build_reply)
        Connections.flood(message.increment!, except_to: self)
      end
    end

    def read_reply(message)
      Connections.add_potential_connection(message.pretty_ip, message.port)
      Connections.store_reply(message)
      if connection = Connections.seen_query?(message.message_id)
        connection.send_message(message)
      else
        no_op(message)
      end
    end

    def read_message(message)
      Connections.count_message(message.type, :in) if message
      logger.debug "Read #{message.class} #{message.message_id}" if message
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
      self.last_read = message 
    end

    def logger
      TellaPeer.logger
    end

    def time_elapsed
      Time.now - start_time
    end

    def inspect
      {
        remote_ip: remote_ip, 
        remote_port: remote_port,
        time_elapsed: time_elapsed,
        text: text,
        direction: direction,
      }.inspect
    end

    def no_op(message)
      logger.debug "Remove #{message.class} #{message.message_id} from network" if message
    end
  end
end