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

  it { expect(message.payload_length).to eq 6 }

  context '#new' do
    context 'building a pong message' do
      let(:packed_message) { message.pack }
      let(:read_message) do
        TellaPeer::Pong.new(packed_message[0..22].unpack(TellaPeer::Message::HEADER_PACKER), packed_message[23..-1])
      end
      it 'payload size is 6 bytes' do
        expect(packed_message[23..-1].length).to eq 6
      end
      [:message_id, :ttl, :hops, :payload_length, :ip, :port].each do |prop|
        it "maintains #{prop}" do
          expect(read_message.send(prop)).to eq message.send(prop)
        end
      end
    end
  end
end