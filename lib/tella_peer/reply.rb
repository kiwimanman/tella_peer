module TellaPeer
  class Reply < Message
    attr_writer :ip, :port, :logger

    def initialize(header = nil, body = '')
      super(header, body)

      unless body.empty?
        content   = body.unpack(payload_unpacker)
        self.port = content[0]
        self.ip   = content[1..4]
        self.text = content[5..-1].map(&:chr).join
      end
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

    def log
      @logger ||= Logger.new(STDOUT)
      @logger.unknown "#{pretty_ip}:#{port} #{text}"
    end

    def payload
      [port] + ip + text.chars.map(&:ord)
    end

    def payload_unpacker
      'n' + 'CCCC' + 'C' * (payload_length - 6)
    end

    def payload_packer
      'n' + 'CCCC' + text.gsub(/./, 'C')
    end

    def text=(value)
      @text = value
      @payload_length = 6 + value.length
      value
    end

    def connection_key
      "#{pretty_ip}:#{port}"
    end

    def text
      @text ? @text : self.text = TellaPeer::Message.text
    end

    def type
      MessageTypes::REPLY
    end
  end
end