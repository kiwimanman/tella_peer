module TellaPeer
  class Query < Message
    def type
      MessageTypes::QUERY
    end

    def build_reply
      reply = Reply.new
      reply.message_id = message_id
      reply
    end
  end
end