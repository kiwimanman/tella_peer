module TellaPeer
  class Pong < Message
    attr_writer :ip, :port

    def initialize(header = nil, body = '')
      super(header, body)

      unless body.empty?
        content   = body.unpack(payload_packer)
        self.port = content.first
        self.ip   = content[1..-1].map(&:to_i)
      end
      self.payload_length = 6
    end

    def ip
      @ip = @ip.map(&:to_i) if @ip && @ip.first.kind_of?(String)
      @ip ||= Message.ip.map(&:to_i)
    end

    def pretty_ip
      ip.map(&:to_s).join('.')
    end

    def key
      "#{pretty_ip}:#{port}"
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