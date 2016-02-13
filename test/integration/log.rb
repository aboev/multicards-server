require 'test_helper'
require 'rubygems'
require 'game'
require 'socket.io-client-simple'
require 'protocol'

class LogTest < ActionDispatch::IntegrationTest

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

  test "Should save game_log entry" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    new_game(user_id1, @@socket1.session_id)
    log = GameLog.where(:gid => "quizlet_415").first
    assert_equal Game::STATUS_SEARCHING_PLAYERS, log.status
    new_game(user_id2, @@socket2.session_id)
    sleep(1)
    
    log = GameLog.where(:gid => "quizlet_415").first
    assert_equal Game::STATUS_IN_PROGRESS, log.status

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

    assert_equal @profile1[:email], filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_END).first["msg_body"]["winner"]["email"]
    log = GameLog.where(:gid => "quizlet_415").first
    assert_equal Game::STATUS_COMPLETED, log.status

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
