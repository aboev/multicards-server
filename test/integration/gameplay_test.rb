require 'test_helper'
require 'rubygems'
require 'game'
require 'socket.io-client-simple'

class GameplayTest < ActionDispatch::IntegrationTest

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
  end

  def teardown
    Game.delete_all
    User.delete_all
    Card.delete_all
    Cardset.delete_all
  end

  test "Should start new game" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_START).length
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_START).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 2, @@sock1_msg_list.length
    assert_equal 2, @@sock2_msg_list.length
  end

  test "Should not start new game" do
    user_id1 = register(@profile1)
    sleep(1)
    game_id = new_game(user_id1, @@socket1.session_id)
    sleep(1)
    assert_equal 0, @@sock1_msg_list.length
  end

  test "Should cleanup game entries after quit" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)
    quit_game(@@socket1)
    sleep(1)
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_STOP).length 
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_STOP).length
    assert_equal 3, @@sock1_msg_list.length
    assert_equal 3, @@sock2_msg_list.length
    game_cnt1 = Game.where(:status => Game::STATUS_SEARCHING_PLAYERS).length
    game_cnt2 = Game.where(:status => Game::STATUS_IN_PROGRESS).length
    assert_equal 0, (game_cnt1 + game_cnt2)
  end

  test "Should send valid question" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)
    question_msg = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)[0][Constants::JSON_SOCK_MSG_BODY]
    question_type = question_msg[Constants::JSON_QST_TYPE]
    question = question_msg[Constants::JSON_QST_QUESTION]
    if question_type == Question::QTYPE_MULTI_CHOICE
      options = question_msg[Constants::JSON_QST_OPTIONS]
      answer_id = question_msg[Constants::JSON_QST_ANSWER_ID]
      answer = options[answer_id]
      assert_equal true, (question.length > 0) 
      assert_equal true, (options.length > 1)
      card = Card.where(:front => question, :back => answer).first
      assert_not_nil card
    elsif question_type == Question::QTYPE_DIRECT_INPUT
      hidden_chars_pos = question_msg[Constants::JSON_QST_OPTIONS]
      answer = question_msg[Constants::JSON_QST_ANSWER_ID]
      assert_equal true, (hidden_chars_pos.length > 0)
      card = Card.where(:front => question, :back => answer).first
      assert_not_nil card
    end
  end

  test "Should send new question after user answer" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)

    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, 0, [])
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)
   
    sleep(1)
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED).length
    assert_equal 2, @@sock1_msg_list.length
    assert_equal 2, @@sock2_msg_list.length
  end

  test "Should stop game after N turns" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)
    
    for i in 0..(Game::QUESTIONS_PER_GAME-2)
      player_answer(@@socket1, 0, [])
      update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
      update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)
      sleep(0.3)
    end

    @@sock1_msg_list = []
    @@sock2_msg_list = []
    player_answer(@@socket1, 0, [])
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    sleep(2)
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_END).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_END).length
  end

  test "Should deliver answer to second player" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)

    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, 0, [])

    sleep(1)
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED).length
  end

  test "Should accept single answer" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)

    answer_id = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, answer_id, [])
    player_answer(@@socket2, answer_id, [])

    sleep(1)
    accepted_cnt_1 = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED).length
    accepted_cnt_2 = filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED).length
    rejected_cnt_1 = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_REJECTED).length
    rejected_cnt_2 = filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_REJECTED).length
    assert_equal 1, (accepted_cnt_1 + accepted_cnt_2)
    assert_equal 1, (rejected_cnt_1 + rejected_cnt_2)
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
