module TellaPeer
  class Pong < Message
    attr_writer :ip, :port

    def initialize(header = nil, body = '')
      super(header, body)

      self.port, self.ip = body.unpack(payload_packer)
      self.payload_length = 5
    end

    def ip
      @ip ||= Message.ip
    end

    def pretty_ip
      ip.join('.')
    end

    def port
      @port ||= Message.port
    end

    def payload
      [port] + ip
    end

    def payload_packer
      'nCCCC'
    end

    def type
      MessageTypes::PONG
    end
  end
end