describe TellaPeer::Pong do
  let(:message) do
    pong = TellaPeer::Pong.new
    pong.port = 1234
    pong.ip = [0,255,128,129]
    pong
  end
  
  it { expect(message.type).to be TellaPeer::MessageTypes::PONG }

  it { expect(message).to respond_to :port }
  it { expect(message).to respond_to :ip   }

  it { expect(message.payload_length).to eq 5 }

  context '#new' do
    context 'building a base message (do not actually send one of these)' do
      let(:read_message) do
        full_message = message.pack
        TellaPeer::Pong.new(full_message[0,23].unpack(TellaPeer::Message::HEADER_PACKER), full_message[24..-1])
      end
      [:message_id, :ttl, :hops, :payload_length].each do |prop|
        it "maintains #{prop}" do
          expect(read_message.send(prop)).to eq message.send(prop)
        end
      end
    end
  end
end