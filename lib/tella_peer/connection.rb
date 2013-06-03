module TellaPeer
  class Connection < Struct.new(:socket, :remote_ip, :remote_port)
    
  end
end