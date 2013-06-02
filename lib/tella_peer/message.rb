require 'uuid'

module TellaPeer
  class Message

    attr_writer :message_id, :ttl, :hops, :payload_length
    attr_accessor :recv_ip, :recv_port

    def initialize(header = nil, body = '')
      if header
        self.message_id     = header[0..15].map(&:chr).join
        self.ttl            = header[17]
        self.hops           = header[18]
        self.payload_length = header[19]
      end
    end

    def message_id
      @message_id ||= UUID.new.generate(:compact)[0..15]
    end

    def type
      MessageTypes::UNKNOWN
    end

    def ttl
      @ttl || 1
    end

    def hops
      @hops || 0
    end

    def payload_length
      @payload_length || 0
    end

    def payload
      []
    end

    def payload_packer
      ''
    end

    def pack
      id = message_id.chars.map { |i| i.ord }
      ((id << type << ttl << hops << payload_length) + payload).pack('C' * 19 + 'N' + payload_packer)
    end

    def self.unpack(socket, ip, port)
      header = socket.read(23).unpack('C' * 19 + 'N')
      body   = socket.read(header.last)

      message = case header[16]
      when -1
        Message.new(header,body)
      when 0
        Ping.new(header,body)
      when 1
        Pong.new(header,body)
      when 2
        Query.new(header,body)
      when 3
        Reply.new(header,body)
      else
        throw "Unknown Type #{header[16]}"
      end

      message.recv_ip = ip
      message.recv_port = port
      message
    end
  end
end