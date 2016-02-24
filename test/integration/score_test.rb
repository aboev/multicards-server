require 'test_helper'
require 'rubygems'
require 'game'
require 'socket.io-client-simple'
require 'protocol'

class ScoreTest < ActionDispatch::IntegrationTest

  @@socket1 = SocketIO::Client::Simple.connect 'http://localhost:5002'
  @@socket2 = SocketIO::Client::Simple.connect 'http://localhost:5002'

  def setup
    @headers = {'Content-Type' => 'application/json', 'Accept' => '*/*'}
    @contact1 = "111111"
    @contact2 = "222222"
    @profile1 = {:email => "test1@test.com", :phone => @contact1, :name => "alex1", :avatar => "http://google.com"}
    @profile2 = {:email => "test2@test.com", :phone => @contact2, :name => "alex2", :avatar => "http://google.com"}
    @@sock1_msg_list = []
    @@sock2_msg_list = []
   
    socket_wait(@@socket1) 
    socket_wait(@@socket2) 
  end

  def teardown
    clear_db
  end

  test "Scores should be zero" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)
    scores = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)[0][Constants::JSON_SOCK_MSG_EXTRA]
    assert_equal 0, scores[@@socket1.session_id]
    assert_equal 0, scores[@@socket2.session_id]
  end

  test "Should increase score after correct answer" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)

    answer_id = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, answer_id, [])
    sleep(0.1)
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    sleep(1)
    scores = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_extra"]
    score1 = scores[@@socket1.session_id]
    score2 = scores[@@socket2.session_id]
    assert_equal score1, 1
    assert_equal score2, 0
  end

  test "Should not increase score after wrong answer" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)

    answer_id = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, answer_id + 1, [])
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    sleep(1)
    scores = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_extra"]
    score1 = scores[@@socket1.session_id]
    score2 = scores[@@socket2.session_id]
    assert_equal score1, 0
    assert_equal score2, 0
  end

  test "Should return winner with highest score" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)

    for i in 0..(Constants::GAMEPLAY_Q_PER_G-2)
      sl = 0
      while ((filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first == nil) and (sl < 20)) do
        sleep (0.1)
        sl = sl + 1
        if (sl % 10 == 0)
          puts "Waiting for " + sl.to_s
        end
      end
      answer_id = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
      @@sock1_msg_list = []
      @@sock2_msg_list = []
      player_answer(@@socket1, answer_id, [])
      sleep(0.1)
      update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
      update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)
      sleep(0.3)
    end

    answer_id = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
    @@sock1_msg_list = []
    @@sock2_msg_list = []
    player_answer(@@socket1, answer_id, [])
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    sleep(2)
    assert_equal @profile1[:email], filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_END).first["msg_body"]["winner"]["email"]
  end

  test "Should increase winner score" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)

    for i in 0..(Constants::GAMEPLAY_Q_PER_G-2)
      answer_id = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
      @@sock1_msg_list = []
      @@sock2_msg_list = []
      player_answer(@@socket1, answer_id, [])
      sleep(0.1)
      update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
      update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)
    end

    answer_id = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
    @@sock1_msg_list = []
    @@sock2_msg_list = []
    player_answer(@@socket1, answer_id, [])
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    target_score = Constants::GAMEPLAY_Q_PER_G + Constants::BONUS_WINNER[:bonus]
    assert_equal target_score, filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_END).first["msg_body"]["scores"][@@socket1.session_id]
    assert_equal 0, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_END).first["msg_body"]["scores"][@@socket2.session_id]
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
