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

  def start_game(userid, socketid, gid, gameid, opponent, multiplayer_type)
    @headers[Constants::HEADER_USERID] = userid
    @headers[Constants::HEADER_SOCKETID] = socketid
    @headers[Constants::HEADER_SETID] = gid
    @headers[Constants::HEADER_OPPONENTNAME] = opponent
    @headers[Constants::HEADER_MULTIPLAYER_TYPE] = multiplayer_type
    @headers[Constants::HEADER_GAMEID] = gameid
    post '/game/new', nil, @headers
    game_id = JSON.parse(@response.body)['data']['id']
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

  def quit_game(socket)
    msg_type = Constants::SOCK_MSG_TYPE_QUIT_GAME
    msg_body = socket.session_id
    msg = Protocol.make_msg(nil, msg_type, msg_body)
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
