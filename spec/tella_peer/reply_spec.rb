describe TellaPeer::Reply do
  let(:message_text) { "Keith Stone -- stonek2@cs.washington.edu"}
  let(:message) do
    reply = TellaPeer::Reply.new
    reply.port = 1234
    reply.ip = [0,255,128,129]
    reply.text = message_text
    reply
  end
  
  it { expect(message.type).to be TellaPeer::MessageTypes::REPLY }

  it { expect(message).to respond_to :port }
  it { expect(message).to respond_to :ip   }
  it { expect(message).to respond_to :text }
  it { expect(message.payload_length).to eq message_text.length + 6 }

  it { expect(message.payload.drop(5)).to eq message_text.chars.map(&:ord) }

  context '#new' do
    context 'building a reply' do
      let(:packed_message) { message.pack }
      let(:read_message) do
        TellaPeer::Reply.new(packed_message[0..22].unpack(TellaPeer::Message::HEADER_PACKER), packed_message[23..-1])
      end
      it 'has a payload the same length as the payload field' do
        expect((packed_message[23..-1] || []).length).to eq message.payload_length
      end
      [:message_id, :ttl, :hops, :payload_length, :text, :ip, :port].each do |prop|
        it "maintains #{prop}" do
          expect(read_message.send(prop)).to eq message.send(prop)
        end
      end
    end
  end
end