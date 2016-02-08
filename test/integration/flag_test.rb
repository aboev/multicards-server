require 'test_helper'
require 'rubygems'
require 'game'
require 'socket.io-client-simple'

class FlagTest < ActionDispatch::IntegrationTest

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

    socket_wait(@@socket1)
    socket_wait(@@socket2)
  end

  def teardown
    clear_db
  end

  test "Should recognize INVERTED flag" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    gid = "quizlet_2"

    setid = Utils.parse_gid(gid)[1]
    cardset = Qcardset.where(:cardset_id => setid).first
    cardset.add_flag(Constants::FLAG_INVERTED)
    cardset.save

    new_game_with_gid(user_id1, @@socket1.session_id, gid)
    new_game_with_gid(user_id2, @@socket2.session_id, gid)

    for i in 0..(3)
      msg_list = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)
      answer_id = msg_list.first["msg_body"][Constants::JSON_QST_ANSWER_ID]
      question_msg = msg_list[0][Constants::JSON_SOCK_MSG_BODY]
      question = question_msg[Constants::JSON_QST_QUESTION]
      options = question_msg[Constants::JSON_QST_OPTIONS]
     
      assert_equal 2, options.size
      set = {}
      options.each do |option|
        assert_not_nil option
        assert_nil set[option]
        set[option] = 1
      end
      assert_equal 1, set['4']
      assert_equal 1, set['2']

      @@sock1_msg_list = []
      player_answer(@@socket1, answer_id, [])
      update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
      update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)
    end

    msg_list_1 = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_END)
    msg_list_2 = filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_END)
    assert_equal 1, msg_list_1.length
    assert_equal 1, msg_list_2.length
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
