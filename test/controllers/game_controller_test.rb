require 'controllers/test_utils'
require 'rubygems'
require 'game'
require 'socket.io-client-simple'

class GameControllerTest < ActionController::TestCase
  include TestUtils

  @@socket1 = SocketIO::Client::Simple.connect 'http://localhost:5002'
  @@socket2 = SocketIO::Client::Simple.connect 'http://localhost:5002'

  def setup
    @request.headers["Content-Type"] = "application/json"
    @request.headers["Accept"] = "*/*"
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
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_END).length 
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_END).length
    assert_equal 3, @@sock1_msg_list.length
    assert_equal 3, @@sock2_msg_list.length
  end

  test "Should send valid question" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)
    question_msg = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)[0][Constants::JSON_SOCK_MSG_BODY]
    question = question_msg[Constants::JSON_QST_QUESTION]
    options = question_msg[Constants::JSON_QST_OPTIONS]
    answer_id = question_msg[Constants::JSON_QST_ANSWER_ID]
    answer = options[answer_id]
    assert_equal true, (question.length > 0) 
    assert_equal true, (options.length > 1)
    card = Card.where(:front => question, :back => answer).first
    assert_not_nil card 
  end

  test "Should send new question after user answer" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    new_game(user_id2, @@socket2.session_id)
    sleep(1)

    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, 0, [@@socket2.session_id])
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)
   
    sleep(1)
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED).length
    assert_equal 1, @@sock1_msg_list.length
    assert_equal 2, @@sock2_msg_list.length
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
