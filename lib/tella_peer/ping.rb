module TellaPeer
  class Ping < Message
    def type
      MessageTypes::PING
    end

    def ping_to_pong
      pong = Pong.new
      pong.message_id = message_id
      pong
    end
    alias_method :build_reply, :ping_to_pong
  end
end