require 'daemons'
require_relative 'constants'
require 'socket.io-client-simple'


class RobotPlayer
  @@log_path = "/home/alex/multicards-server/lib/log.txt"
  @@http_host = 'http://localhost:3000'
  @@http_host_test = 'http://localhost:3000'
  @@http_host_prod = 'http://localhost'
  @@http_host_dev = 'http://localhost:8080'
  @@msg_list = []
  @@userid = -1

  @STATUS_WAITING = 0
  @STATUS_IN_PROGRESS = 1
  @STATUS = 0

  PLAYER_STATUS_PENDING = "player_pending"
  PLAYER_STATUS_WAITING = "player_waiting"
  PLAYER_STATUS_THINKING = "player_thinking"
  PLAYER_STATUS_ANSWERED = "player_answered"

  def log(msg)
    puts msg
    File.open(@@log_path,"a+") {|f| f.write(msg + "\n") }
  end

  def make_msg(id_to, msg_type, msg_body)
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

  def socket_emit(msg_to, msg_type, msg_body)
    msg = make_msg(msg_to, msg_type, msg_body)
    puts "[outgoing] Sending message " + msg.to_s
    @@socket.emit :message, msg
  end

  def announce_user_id(userid)
    msg_type = Constants::SOCK_MSG_TYPE_ANNOUNCE_USERID
    msg_body = userid
    socket_emit(nil, msg_type, msg_body)
  end

  def status_update(status)
    msg_type = Constants::SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE
    msg_body = status
    socket_emit(nil, msg_type, msg_body)
  end

  def accept_game(game_id)
    msg_type = Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED
    msg_body = game_id
    socket_emit(nil, msg_type, msg_body)
  end

  def answer(question)
    options = question[Constants::JSON_QST_OPTIONS]
    msg_type = Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED
    msg_body = Random.rand(0...options.length)
    socket_emit(nil, msg_type, msg_body)
  end

  def msg_game_invite(id_from, invitation_json)
    game_id = invitation_json[Constants::JSON_INVITATION_GAME][Constants::JSON_GAME_ID]
    accept_game(game_id)
  end

  def parse_msg(msg_json)
    log("[incoming] Parsing message: " + msg_json.to_s)
    id_from = msg_json[Constants::JSON_SOCK_MSG_FROM]
    msg_to = msg_json[Constants::JSON_SOCK_MSG_TO]
    msg_type = msg_json[Constants::JSON_SOCK_MSG_TYPE]
    msg_body = msg_json[Constants::JSON_SOCK_MSG_BODY]
    msg_extra = msg_json[Constants::JSON_SOCK_MSG_EXTRA]
    msg_id = msg_json[Constants::JSON_SOCK_MSG_ID]

    if (msg_type == Constants::SOCK_MSG_TYPE_GAME_INVITE)
      msg_game_invite(id_from, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_GAME_START)
      @STATUS = @STATUS_IN_PROGRESS
    elsif (msg_type == Constants::SOCK_MSG_TYPE_NEW_QUESTION)
      answer(msg_body)    
      status_update(PLAYER_STATUS_WAITING)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE)
      if ((@STATUS == @STATUS_WAITING) and (msg_body == PLAYER_STATUS_WAITING))
        status_update(PLAYER_STATUS_WAITING)
      end
    elsif (msg_type == Constants::SOCK_MSG_TYPE_GAME_END)
      @STATUS == @STATUS_WAITING
    elsif (msg_type == Constants::SOCK_MSG_TYPE_GAME_STOP)
      @STATUS == @STATUS_WAITING
    elsif (msg_type == Constants::SOCK_MSG_TYPE_QUIT_GAME)
      @STATUS == @STATUS_WAITING
    end
  end

  def start(socket, userid, http_host)
    @@http_host = http_host
    @@userid = userid == nil ? register : userid
    announce_user_id(@@userid)
    
    puts "session_id = " + socket.session_id
    puts "user_id = " + userid.to_s
    @STATUS = @STATUS_WAITING
    socket.on :event do |msg|
      msg_json = JSON.parse(msg)
      @@msg_list << msg_json
    end
  end
  
  def msg_list
    @@msg_list
  end
  
  def msg_list_clear
    @@msg_list = []
  end

end

@socket_host = 'http://localhost:5002'
@socket_host_test = 'http://localhost:5002'
@socket_host_prod = 'http://localhost:5001'
@socket_host_dev = 'http://localhost:5003'

@http_host = 'http://localhost:3000'
@http_host_test = 'http://localhost:3000'
@http_host_prod = 'http://localhost:8080'
@http_host_dev = 'http://localhost:8081'

@userid = nil

def parse_arg(key, value)
  if key == "env"
    @socket_host = @socket_host_test if value == "test"
    @socket_host = @socket_host_prod if value == "prod"
    @socket_host = @socket_host_dev if value == "dev"
    @http_host = @http_host_test if value == "test"
    @http_host = @http_host_prod if value == "prod"
    @http_host = @http_host_dev if value == "dev"
  elsif key == "userid"
    @userid = value
  end
end

Daemons.run_proc('robot_player.rb') do
  ARGV.each do |arg|
    key = arg.split("=")[0]
    value = arg.split("=")[1]
    parse_arg(key, value)
  end
  @@socket = SocketIO::Client::Simple.connect @socket_host
  sleep(0.1)
  robot = RobotPlayer.new
  robot.start(@@socket, @userid, @http_host)
  loop do
    robot.msg_list.each do |msg|
      robot.parse_msg(msg)
    end
    robot.msg_list_clear
    sleep(5)
  end
end
