module TellaPeer
  class Reply < Message
    attr_writer :ip, :port, :logger

    def initialize(header = nil, body = '')
      super(header, body)

      unless body.empty?
        content   = body.unpack(payload_packer)
        self.port = content.first
        self.ip   = content[1..5]
        self.text = content[4..-1].map(&:chr).join
      end
      self.payload_length = body.length
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
      logger.unknown "#{pretty_ip}:#{port} #{text}"
    end

    def payload
      [port] + ip + text.chars.map(&:ord)
    end

    def payload_packer
      'nCCCC' + 'C' * (payload_length - 6)
    end

    def text=(value)
      @text = value
      @payload_length = 6 + value.length
      value
    end

    def text
      @text ? @text : self.text = TellaPeer::Message.text
    end

    def type
      MessageTypes::REPLY
    end
  end
end