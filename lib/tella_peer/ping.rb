module TellaPeer
  class Ping < Message
    def type
      MessageTypes::PING
    end
  end
end