module TellaPeer
  class Reply < Message
    def type
      MessageTypes::REPLY
    end
  end
end