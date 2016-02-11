require 'question'
require 'constants'
require 'game'
require 'socket.io-client-simple'

class RobotPlayer
  @sockets = {}

  def socket_wait(socket)
    lim = 20
    i = 0
    while ((socket.state.to_s != "connect".to_s) and (i < lim)) do
      i = i + 1
      sleep(0.1)
    end
    if i == lim
      puts "Socket failed to connect"
    end
  end

  def make_name
    
  end

  def self.start(gid)
    socket = SocketIO::Client::Simple.connect 'http://localhost:5002'
    socket_wait(socket)
    @sockets[socket.session_id] = socket

    robot = User.new
    robot.details = {:name => }.to_json
    user.score = 0
    user.status = Constants::STATUS_ONLINE
    user.save
    user.init
  end

  def self.new_game(user, gid)
    game = Game.new
    game.init(gid, rnd_opp)
    game.join_player(user, Game::PLAYER_STATUS_PENDING)
    GameLog.log(game)
  end

end
