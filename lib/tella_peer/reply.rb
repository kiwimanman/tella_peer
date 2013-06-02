module TellaPeer
  class Reply < Message
    attr_accessor :ip, :port

    def initialize(header = nil, body = '')
      super(header, body)

      self.port, self.ip = body.unpack(payload_packer)
      self.payload_length = body.length
    end

    def payload
      [port] + ip + text.chars.map(&:ord)
    end

    def payload_packer
      'nCCCC' + 'C' * text.length
    end

    def text=(value)
      @text = value
      @payload_length = 5 + value.length
      value
    end

    def text
      @text ||= ''
    end

    def type
      MessageTypes::REPLY
    end
  end
end