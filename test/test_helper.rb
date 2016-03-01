ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all
  self.use_transactional_fixtures = false
  # Add more helper methods to be used by all tests here...

  def clear_db
    Game.delete_all
    User.delete_all
    Card.delete_all
    Cardset.delete_all
    Qcardset.delete_all
    Qcard.delete_all
    TagDescriptor.delete_all
    GameLog.delete_all
    TagLog.delete_all
    FlagLog.delete_all
  end

  def register(profile)
    post '/user', profile.to_json, @headers
    assert_response :success
    user_id = JSON.parse(@response.body)['data']['id']
  end

  def announce_userid(socket, userid)
    msg_type = Constants::SOCK_MSG_TYPE_ANNOUNCE_USERID
    msg_body = userid
    msg = Protocol.make_msg(nil, msg_type, msg_body)
    socket.emit :message, msg
  end

  def quit_game(socket)
    msg_type = Constants::SOCK_MSG_TYPE_QUIT_GAME
    msg = Protocol.make_msg(nil, msg_type, nil)
    socket.emit :message, msg
  end

  def new_game(userid, socketid)
    @headers[Constants::HEADER_USERID] = userid
    @headers[Constants::HEADER_SOCKETID] = socketid
    @headers[Constants::HEADER_SETID] = "quizlet_415"
    if (socketid == nil)
      puts "socketid = nil"
    end
    post '/game', nil, @headers
    game_id = JSON.parse(@response.body)['data']['id']
  end

  def new_game_with_gid(userid, socketid, gid)
    @headers[Constants::HEADER_USERID] = userid
    @headers[Constants::HEADER_SOCKETID] = socketid
    @headers[Constants::HEADER_SETID] = gid
    if (socketid == nil)
      puts "socketid = nil"
    end
    post '/game', nil, @headers
    game_id = JSON.parse(@response.body)['data']['id']
  end

  def new_game_with_opponent(userid, socketid, opponent_name)
    @headers[Constants::HEADER_USERID] = userid
    @headers[Constants::HEADER_SOCKETID] = socketid
    @headers[Constants::HEADER_OPPONENTNAME] = opponent_name
    post '/game', nil, @headers
    if JSON.parse(@response.body)[:result] == Constants::RESULT_OK
      game_id = JSON.parse(@response.body)['data']['id']
      return game_id
    end
  end

  def new_game_v2(userid, socketid, new_game, gid, opponent_name)
    multiplayer_type = Constants::MULTIPLAYER_TYPE_NEW
    multiplayer_type = Constants::MULTIPLAYER_TYPE_JOIN if (new_game == false) 
    @headers[Constants::HEADER_USERID] = userid
    @headers[Constants::HEADER_SOCKETID] = socketid
    @headers[Constants::HEADER_OPPONENTNAME] = opponent_name
    @headers[Constants::HEADER_MULTIPLAYER_TYPE] = multiplayer_type
    @headers[Constants::HEADER_SETID] = gid
    post '/game/new', nil, @headers
    if JSON.parse(@response.body)['result'] == Constants::RESULT_OK
      game_id = JSON.parse(@response.body)['data'][Constants::JSON_GAME_ID]
      return game_id
    else
      return JSON.parse(@response.body)
    end
  end

  def start_game_v2(userid1, socket1, sock1_msg_list, gid, userid2, socket2, sock2_msg_list)
    user = User.where(:id => userid1).first
    name = JSON.parse(user.details)["name"]
    game_id = new_game_v2(userid1, socket1.session_id, true, gid, nil)
    new_game_v2(userid2, socket2.session_id, false, nil, name)
    game_id = JSON.parse(@response.body)['data'][Constants::JSON_GAME_ID]
    update_client_status(socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(socket2, Game::PLAYER_STATUS_WAITING)
    assert_equal 1, filter_wait(sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_START).length
  end

  def get_games(userid, socketid)
    @headers[Constants::HEADER_USERID] = userid
    @headers[Constants::HEADER_SOCKETID] = socketid
    @controller = GameController.new
    get '/game', nil, @headers
    games = JSON.parse(@response.body)['data']
  end

  def update_client_status(socket, status)
    msg_type = Constants::SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE
    msg_body = status
    msg = Protocol.make_msg(nil, msg_type, msg_body)
    socket.emit :message, msg
  end

  def player_answer(socket, answer_id, id_to)
    msg_type = Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED
    msg_body = answer_id
    msg = Protocol.make_msg(id_to, msg_type, msg_body)
    socket.emit :message, msg
  end

  def player_answer_confirm(socket, answer_id, id_to, msg_id)
    msg_type = Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED
    msg_body = answer_id
    msg = {Constants::JSON_SOCK_MSG_ID => msg_id, Constants::JSON_SOCK_MSG_TO => id_to, Constants::JSON_SOCK_MSG_TYPE => msg_type, Constants::JSON_SOCK_MSG_BODY => msg_body}.to_json
    socket.emit :message, msg
  end

  def quit_game(socket)
    msg_type = Constants::SOCK_MSG_TYPE_QUIT_GAME
    msg_body = socket.session_id
    msg = Protocol.make_msg(nil, msg_type, msg_body)
    socket.emit :message, msg
  end

  def accept_invite(socket, game_id)
    msg_type = Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED
    msg_body = game_id
    msg = Protocol.make_msg(nil, msg_type, msg_body)
    socket.emit :message, msg
  end

  def accept_invite_extra(socket, game_id, invitation)
    msg_type = Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED
    msg_body = game_id
    msg_extra = invitation
    msg = Protocol.make_msg_extra(nil, msg_type, msg_body, msg_extra)
    socket.emit :message, msg
  end

  def filter(list, msg_type)
    res = []
    list.each do |msg|
      if msg[Constants::JSON_SOCK_MSG_TYPE] == msg_type
        res << msg
      end
    end
    return res
  end

  def filter_wait(list, msg_type)
    sl = 0
    lim = 40
    while ((filter(list, msg_type).first == nil) and (sl < lim)) do
      sleep (0.1)
      sl = sl + 1
    end
    if (sl == lim)
      #puts "Failed to wait for " + msg_type.to_s
    end
    return filter(list, msg_type)
  end

  def filter_wait_multi(list, msg_types)
    sl = 0
    lim = 40
    r = false
    while (r == false and (sl < lim)) do
      msg_types.each do |type|
        r = true if filter(list, msg_type).first != nil
      end
      sleep (0.1)
      sl = sl + 1
    end
    if (sl == lim)
      #puts "Failed to wait for " + msg_type.to_s
    end
    return filter(list, msg_type)
  end

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

  def socket_wait_disconnect(socket)
    lim = 20
    i = 0
    while ((socket.open?) and (i < lim)) do
      i = i + 1
      sleep(0.1)
    end
    if i == lim
      puts "Socket failed to disconnect"
    end
  end

  def has_bonus(bonus_list, bonus_id)
    res = false
    bonus_list.each do |bonus|
      if bonus["bonus_id"] == bonus_id
        res = true
        break
      end
    end
    return res
  end

end
