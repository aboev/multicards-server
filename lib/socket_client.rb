require 'socket.io-client-simple'

env = ARGV[0] == nil ? "test" : ARGV[0]
port = 5002
port = 5001 if env == "production"
port = 5003 if env == "development"

socket = SocketIO::Client::Simple.connect 'http://localhost:' + port.to_s

socket.on :event do |msg|
  msg_json = JSON.parse(msg)
  puts "Received socket message " + msg
end

while (line = STDIN.gets.chomp) != "end" 
  socket.emit :message, line
end
