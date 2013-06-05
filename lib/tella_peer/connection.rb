module TellaPeer
  class Connection < Struct.new(:socket, :remote_ip, :remote_port)
    attr_accessor :start_time, :text

    def initialize(socket, remote_ip, remote_port)
      super(socket, remote_ip, remote_port)
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
          logger.warn $!
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
        to.write(message.pack) if message.transmitable?
      rescue
        logger.debug "Write to #{key} failed -- #{$!.message}"
        close_socket
      end
    end

    def read_ping(message)
      if Connections.seen_ping?(message.message_id, from: self)
        no_op(message)
      else
        send_message(message.build_reply, increment: true)
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
        send_message(message.build_reply, increment: true)
        Connections.flood(message.increment!, except_to: self)
      end
    end

    def read_reply(message)
      Connections.store_reply(message)
      if connection = Connections.seen_query?(message.message_id)
        connection.send_message(message)
      else
        no_op(message)
      end
    end

    def read_message(message)
      logger.debug "Read #{message.class} #{message.message_id}"
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

    def logger
      TellaPeer.logger
    end

    def inspect
      {
        remote_ip: remote_ip, 
        remote_port: remote_port,
        time_elapsed: Time.now - start_time,
        text: text
      }.inspect
    end

    def no_op(message)
      logger.debug "Remove #{message.class} #{message.message_id} from network"
    end
  end
end