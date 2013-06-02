describe TellaPeer::Pong do
  let(:message) do
    TellaPeer::Pong.new
  end
  
  it { expect(message.type).to be TellaPeer::MessageTypes::PONG }
end