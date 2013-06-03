module TellaPeer
  class Pong < Message
    attr_writer :ip, :port

    def initialize(header = nil, body = '')
      super(header, body)

      unless body.empty?
        content   = body.unpack(payload_packer)
        self.port = content.first
        self.ip   = content[1..-1]
      end
      self.payload_length = 6
    end

    def ip
      @ip ||= Message.ip
    end

    def pretty_ip
      ip.map(&:to_s).join('.')
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