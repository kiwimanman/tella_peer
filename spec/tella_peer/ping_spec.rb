describe TellaPeer::Ping do
  let(:message) do
    TellaPeer::Ping.new
  end
  
  it { expect(message.type).to be TellaPeer::MessageTypes::PING }

  context '#ping_to_pong' do
    let(:pong) { message.ping_to_pong }

    it { expect(pong.message_id).to eq message.message_id }
  end
end