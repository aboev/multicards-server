require 'test_helper'
require 'rubygems'
require 'game'
require 'socket.io-client-simple'

class MultiplayerLinkTest < ActionDispatch::IntegrationTest

  @@socket1 = SocketIO::Client::Simple.connect 'http://localhost:5002'
  @@socket2 = SocketIO::Client::Simple.connect 'http://localhost:5002'

  def setup
    @headers = {'Content-Type' => 'application/json', 'Accept' => '*/*'}
    @contact1 = "111111"
    @contact2 = "222222"
    @contact3 = "333333"
    @profile1 = {:email => "test1@test.com", :phone => @contact1, :name => "alex1", :avatar => "http://google.com"}
    @profile2 = {:email => "test2@test.com", :phone => @contact2, :name => "alex2", :avatar => "http://google.com"}
    @profile3 = {:email => "test3@test.com", :phone => @contact3, :name => "alex3", :avatar => "http://google.com"}
    @@sock1_msg_list = []
    @@sock2_msg_list = []

    @gid = "quizlet_415"

    socket_wait(@@socket1)
    socket_wait(@@socket2)
  end

  def teardown
    clear_db
  end

  test "Should send invitation for private game" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    announce_userid(@@socket2, user_id2)

    game_id = new_game_v2(user_id1, @@socket1.session_id, true, @gid, @profile2[:name])
    msg_invite = filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_INVITE).first["msg_body"]
    assert_equal @profile1[:name], msg_invite[Constants::JSON_INVITATION_USER]["name"]
    assert_equal game_id, msg_invite[Constants::JSON_INVITATION_GAME][Constants::JSON_GAME_ID]
    assert_equal Utils.parse_gid(@gid)[1], msg_invite[Constants::JSON_INVITATION_CARDSET]["cardset_id"].to_s
  end

  test "Should accept invitation for private game" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    get_games(user_id2, @@socket2.session_id)

    game_id = new_game_v2(user_id1, @@socket1.session_id, true, @gid, @profile2[:name])
    msg_invite = filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_INVITE).first["msg_body"]

    accept_invite(@@socket2, game_id)
    msg_accepted = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED).first["msg_body"]
    game = Game.where(:id => game_id).first
    game_details = JSON.parse(game.details)
    assert_equal Game::PLAYER_STATUS_PENDING, game_details[Constants::JSON_GAME_PLAYERS][@@socket2.session_id]
  end

  test "Should start private game by invitation" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    get_games(user_id2, @@socket2.session_id)

    game_id = new_game_v2(user_id1, @@socket1.session_id, true, @gid, @profile2[:name])
    msg_invite = filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_INVITE).first["msg_body"]

    accept_invite(@@socket2, game_id)
    msg_accepted = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED).first["msg_body"]

    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    assert_equal 1, filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_START).length
    assert_equal 1, filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_START).length
    assert_equal 1, filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
  end

  test "Should start public game without invitation" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    get_games(user_id2, @@socket2.session_id)

    game_id = new_game_v2(user_id1, @@socket1.session_id, true, @gid, nil)

    new_game_v2(user_id2, @@socket2.session_id, false, nil, @profile1[:name])

    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    assert_equal 1, filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_START).length
    assert_equal 1, filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_START).length
    assert_equal 1, filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
  end

  test "Should hide private games from list" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    user_id3 = register(@profile3)
    @@socket3 = SocketIO::Client::Simple.connect 'http://localhost:5002'
    game_id1 = new_game_v2(user_id1, @@socket1.session_id, true, @gid, nil)
    game_id2 = new_game_v2(user_id1, @@socket1.session_id, true, @gid, @profile1[:name])
    list = get_games(user_id3, @@socket3.session_id)
    assert_equal 1, list.length
    assert_equal game_id1, list[0]["id"]
  end

  test "Should return error for non-existing cardset" do
    user_id1 = register(@profile1)
    response = new_game_v2(user_id1, @@socket1.session_id, true, "aaa", "aaa")
    assert_equal Constants::RESULT_ERROR, response['result']
    assert_equal Constants::ERROR_CARDSET_NOT_FOUND, response['code']
  end

  test "Should return error for non-existing user" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    response = new_game_v2(user_id2, @@socket2.session_id, false, "aaa", @profile1[:name])
    assert_equal Constants::RESULT_ERROR, response['result']
    assert_equal Constants::ERROR_GAME_NOT_FOUND, response['code']
  end

  @@socket1.on :event do |msg|
    msg_json = JSON.parse(msg)
    @@sock1_msg_list << msg_json
  end

  @@socket2.on :event do |msg|
    msg_json = JSON.parse(msg)
    @@sock2_msg_list << msg_json
  end

end
