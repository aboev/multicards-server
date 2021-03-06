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
    @contact3 = "333333"
    @profile1 = {:email => "test1@test.com", :phone => @contact1, :name => "alex1", :avatar => "http://google.com"}
    @profile2 = {:email => "test2@test.com", :phone => @contact2, :name => "alex2", :avatar => "http://google.com"}
    @profile3 = {:email => "test3@test.com", :phone => @contact3, :name => "alex3", :avatar => "http://google.com"}
    @@sock1_msg_list = []
    @@sock2_msg_list = []

    @gid = "quizlet_415"
    @gid_image = "quizlet_117954645"

    socket_wait(@@socket1)
    socket_wait(@@socket2)
  end

  def teardown
    clear_db
  end

  test "Should cleanup game entries after quit" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid, user_id2, @@socket2, @@sock2_msg_list)

    quit_game(@@socket1)

    assert_equal 1, filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_STOP).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_STOP).length
    assert_equal 5, @@sock1_msg_list.length
    assert_equal 5, @@sock2_msg_list.length
    game_cnt1 = Game.where(:status => Game::STATUS_SEARCHING_PLAYERS).length
    game_cnt2 = Game.where(:status => Game::STATUS_IN_PROGRESS).length
    game_cnt3 = Game.where(:status => Game::STATUS_WAITING_OPPONENT).length
    assert_equal 0, (game_cnt1 + game_cnt2 + game_cnt3)
  end

  test "Should send valid question" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid, user_id2, @@socket2, @@sock2_msg_list)

    question_msg = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)[0][Constants::JSON_SOCK_MSG_BODY]
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
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid, user_id2, @@socket2, @@sock2_msg_list)

    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, 0, [])
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    assert_equal 1, filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEXT_QUESTION).length
    assert_equal 1, filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).length
    assert_equal 1, filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_NEXT_QUESTION).length
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED).length
    assert_equal 3, @@sock1_msg_list.length
    assert_equal 3, @@sock2_msg_list.length
  end

  test "Should confirm socket message" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid, user_id2, @@socket2, @@sock2_msg_list)

    @@sock2_msg_list = []
    @@sock1_msg_list = []
    msg_id = 123
    player_answer_confirm(@@socket1, 0, [], msg_id)

    msg_confirm = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_CONFIRM).first
    assert_equal msg_id, msg_confirm[Constants::JSON_SOCK_MSG_BODY]
  end

  test "Should stop game after N turns" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid, user_id2, @@socket2, @@sock2_msg_list)

    for i in 0..(Game::QUESTIONS_PER_GAME - 2)
      msg_list = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)
      answer_id = msg_list.first["msg_body"][Constants::JSON_QST_ANSWER_ID]
      @@sock1_msg_list = []
      player_answer(@@socket1, answer_id, [])
      update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
      update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)
    end

    msg_list = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)
    @@sock1_msg_list = []
    @@sock2_msg_list = []
    player_answer(@@socket1, 0, [])
    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    msg_list_1 = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_GAME_END)
    msg_list_2 = filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_GAME_END)
    assert_equal 1, msg_list_1.length
    assert_equal 1, msg_list_2.length
  end

  test "Should deliver answer to second player" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid, user_id2, @@socket2, @@sock2_msg_list)

    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, 0, [])

    sleep(1)
    assert_equal 1, filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED).length
  end

  test "Should accept single correct answer" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid, user_id2, @@socket2, @@sock2_msg_list)

    answer_id = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, answer_id.to_s, [])
    player_answer(@@socket2, answer_id.to_s, [])

    accepted_cnt_1 = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED).length
    accepted_cnt_2 = filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED).length
    rejected_cnt_1 = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_REJECTED).length
    rejected_cnt_2 = filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_REJECTED).length
    assert_equal 1, (accepted_cnt_1 + accepted_cnt_2)
    assert_equal 1, (rejected_cnt_1 + rejected_cnt_2)

    update_client_status(@@socket1, Game::PLAYER_STATUS_WAITING)
    update_client_status(@@socket2, Game::PLAYER_STATUS_WAITING)

    answer_id = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
    @@sock1_msg_list = []
    @@sock2_msg_list = []
    player_answer(@@socket1, answer_id + 1, [])
    player_answer(@@socket2, answer_id, [])

    accepted_cnt_1 = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED).length
    accepted_cnt_2 = filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED).length
    rejected_cnt_1 = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_REJECTED).length
    rejected_cnt_2 = filter_wait(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_REJECTED).length
    assert_equal 2, (accepted_cnt_1 + accepted_cnt_2) # Should be reconsidered
    assert_equal 0, (rejected_cnt_1 + rejected_cnt_2)

  end

  test "Should accept both wrong answers" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid, user_id2, @@socket2, @@sock2_msg_list)

    answer_id = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION).first["msg_body"][Constants::JSON_QST_ANSWER_ID]
    @@sock2_msg_list = []
    @@sock1_msg_list = []
    player_answer(@@socket1, answer_id + 1, [])
    player_answer(@@socket2, answer_id + 1, [])

    sleep(1)
    accepted_cnt_1 = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED).length
    accepted_cnt_2 = filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED).length
    rejected_cnt_1 = filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_REJECTED).length
    rejected_cnt_2 = filter(@@sock2_msg_list, Constants::SOCK_MSG_TYPE_ANSWER_REJECTED).length
    assert_equal 2, (accepted_cnt_1 + accepted_cnt_2)
    assert_equal 0, (rejected_cnt_1 + rejected_cnt_2)
  end

  test "Should generate question without duplicate options" do
    gid = "quizlet_10342218"
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    Utils.import_qcardset(gid)

    setid = Utils.parse_gid(gid)[1]
    cardset = Qcardset.where(:cardset_id => setid).first
    cardset.add_flag(Constants::FLAG_INVERTED)
    cardset.save

    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, gid, user_id2, @@socket2, @@sock2_msg_list)

    for i in 0..(Game::QUESTIONS_PER_GAME - 1)
      msg_list = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)
      answer_id = msg_list.first["msg_body"][Constants::JSON_QST_ANSWER_ID]
      question_msg = msg_list[0][Constants::JSON_SOCK_MSG_BODY]
      question = question_msg[Constants::JSON_QST_QUESTION]
      options = question_msg[Constants::JSON_QST_OPTIONS]

      set = {}
      options.each do |option|
        assert_not_nil option
        assert_nil set[option]
        set[option] = 1
      end

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

  test "Should generate question with images" do
    user_id1 = register(@profile1)
    user_id2 = register(@profile2)
    start_game_v2(user_id1, @@socket1, @@sock1_msg_list, @gid_image, user_id2, @@socket2, @@sock2_msg_list)

    question_msg = filter_wait(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_NEW_QUESTION)[0][Constants::JSON_SOCK_MSG_BODY]
    question_type = question_msg[Constants::JSON_QST_TYPE]
    question = question_msg[Constants::JSON_QST_QUESTION]
    options = question_msg[Constants::JSON_QST_OPTIONS_IMG]
    assert_not_nil options[0][Constants::JSON_OPTION_IMAGE]
    assert_not_nil options[0][Constants::JSON_OPTION_TEXT]
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
