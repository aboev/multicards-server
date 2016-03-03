require 'daemons'
require_relative 'constants'
require 'socket.io-client-simple'


class RobotPlayer
  @@log_path = "/home/alex/multicards-server/lib/log.txt"
  @@socket_host = 'http://localhost:5002'
  @@http_host = 'http://localhost:3000'
  @@msg_list = []
  @@userid = -1

  def log(msg)
    puts msg
    File.open(@@log_path,"a+") {|f| f.write(msg + "\n") }
  end

  def self.make_msg(id_to, msg_type, msg_body)
    message = {Constants::JSON_SOCK_MSG_TO => id_to, Constants::JSON_SOCK_MSG_TYPE => msg_type, Constants::JSON_SOCK_MSG_BODY => msg_body}.to_json
    return message
  end

  def register
    uri = URI.parse(@@http_host)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new('/user',
      {'Content-Type' => 'application/json'})
    request.body = "{}"
    response = http.request(request)
    response_json = JSON.parse(response.body)
    userid = response_json['data'][Constants::JSON_USER_ID]
  end

  def accept_game(game_id)
    msg_type = Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED
    msg_body = game_id
    msg = make_msg(nil, msg_type, msg_body)
    @@socket.emit :message, msg
  end

  def msg_game_invite(id_from, invitation)
    invitation_json = JSON.parse(invitation)
    game_id = invitation_json[Constants::JSON_INVITATION_GAME][Constants::JSON_GAME_ID]
    accept_game(game_id)
  end

  def parse_msg(msg)
    id_from = msg_json[Constants::JSON_SOCK_MSG_FROM]
    msg_to = msg_json[Constants::JSON_SOCK_MSG_TO]
    msg_type = msg_json[Constants::JSON_SOCK_MSG_TYPE]
    msg_body = msg_json[Constants::JSON_SOCK_MSG_BODY]
    msg_extra = msg_json[Constants::JSON_SOCK_MSG_EXTRA]
    msg_id = msg_json[Constants::JSON_SOCK_MSG_ID]

    if (msg_type == Constants::SOCK_MSG_TYPE_GAME_INVITE)
      msg_game_invite(id_from, msg_body)
    end
  end

  def start(socket)
    @@userid = register
    puts "Socket session_id " + socket.session_id
    socket.on :event do |msg|
      puts msg
      msg_json = JSON.parse(msg)
      @@msg_list << msg_json
      parse_msg(msg_json)
      log("Received socket message: " + msg)
    end
  end

end

Daemons.run_proc('robot_player.rb') do
  @@socket = SocketIO::Client::Simple.connect 'http://localhost:5002'
  robot = RobotPlayer.new
  robot.start(@@socket)
  loop do
    sleep(5)
  end
end
