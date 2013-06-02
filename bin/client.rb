#!/usr/bin/env ruby

require 'tella_peer'
 
if false
Socket.tcp_server_loop("128.208.2.88", 5002) {|sock, client_addrinfo|
  Thread.new {
    message
    begin
      message = sock.read(22)
    ensure
      sock.close
    end
    puts 
  }
}
end

ip = "128.208.2.88"
port = 5002

s = TCPSocket.open(ip, port)
s.binmode

s.write TellaPeer::Ping.new.pack

loop do
  message = TellaPeer::Message.unpack(s, ip, port)
  debugger
end

s.close