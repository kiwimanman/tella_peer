describe TellaPeer::Message do
  let(:message) { TellaPeer::Message.new }

  context '#type' do
    it 'starts off as unknown' do
      expect(message.type).to be TellaPeer::MessageTypes::UNKNOWN
    end
  end

  context 'class defaults' do
    it { expect(TellaPeer::Message.ip  ).to eq [127, 0, 0, 1] }
    it { expect(TellaPeer::Message.port).to eq 9000           }
    it { expect(TellaPeer::Message.ttl ).to eq 5              }
  end

  [:message_id, :type, :ttl, :hops, :payload_length, :pack, :recv_ip, :recv_port, :increment!].each do |method_name|
    it { expect(message).to respond_to method_name }
  end

  context '#message_id' do
    it 'makes a message_id if none supplied' do
      expect(message.message_id).to_not be nil
    end
    it { expect(message.message_id.length).to eq 16 }

    context 'when compared to other messages' do
      let(:other_message) { TellaPeer::Message.new }
      it { expect(message.message_id).to_not eq other_message.message_id }
    end
  end

  context '#increment!' do
    it 'decrements ttl' do
      expect{message.increment!}.to change{message.ttl}.by(-1)
    end
    it 'increments hops' do
      expect{message.increment!}.to change{message.hops}.by(1)
    end
  end

  context '#ttl' do
    it "starts off at #{TellaPeer::Message.ttl}" do
      expect(message.ttl).to be TellaPeer::Message.ttl
    end
  end

  context '#hops' do
    it 'starts off at 0' do
      expect(message.hops).to be 0
    end
  end

  context '#payload_length' do
    it 'starts off at 0' do
      expect(message.payload_length).to be 0
    end
  end

  context '#pack' do
    it 'creates the right packed message to transmit' do
      expect(message.pack).to_not be nil
    end
  end

  context '#new' do
    context 'building a base message (do not actually send one of these)' do
      let(:packed_message)   { message.pack }
      let(:read_message) do
        TellaPeer::Message.new(packed_message[0,23].unpack(TellaPeer::Message::HEADER_PACKER), packed_message[23..-1])
      end
      it 'has a payload the same length as the payload field' do
        expect((packed_message[23..-1] || []).length).to eq message.payload_length
      end
      [:message_id, :ttl, :hops, :payload_length].each do |prop|
        it "maintains #{prop}" do
          expect(read_message.send(prop)).to eq message.send(prop)
        end
      end
    end
  end
end