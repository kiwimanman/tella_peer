module TellaPeer
  class Query < Message
    def type
      MessageTypes::QUERY
    end
  end
end