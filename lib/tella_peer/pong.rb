module TellaPeer
  class Pong < Message
    def type
      MessageTypes::PONG
    end
  end
end