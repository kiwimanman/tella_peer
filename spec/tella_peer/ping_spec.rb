describe TellaPeer::Ping do
  let(:message) do
    TellaPeer::Ping.new
  end
  
  it { expect(message.type).to be TellaPeer::MessageTypes::PING }
end