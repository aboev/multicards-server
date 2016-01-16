require 'rubygems'
require 'socket.io-client-simple'
require 'test_helper'

class CardsetControllerTest < ActionController::TestCase
  
  @@socket = SocketIO::Client::Simple.connect 'http://localhost:5002'

  def register(profile)
    @controller = UserController.new
    post :new, profile.to_json, @headers
    assert_response :success
    user_id = JSON.parse(@response.body)['data']['id']
  end

  def setup
    @request.headers["Content-Type"] = "application/json"
    @request.headers["Accept"] = "*/*"
    @contact = "111111"
    @profile = {:email => "test@test.com", :phone => @contact, :name => "alex", :avatar => "http://google.com"}
    @userid = register(@profile)
    @request.headers[Constants::HEADER_USERID] = @userid
    @request.headers[Constants::HEADER_SOCKETID] = @@socket.session_id
  end

  def teardown
    clear_db
  end

  test "Should import new cardset" do
    cardset = Qcardset.where(:cardset_id => 415)
    assert_equal 0, cardset.count
    @controller = CardsetController.new
    @request.headers["setid"] = "quizlet_415"
    get :import, nil, @headers
    assert_response :success
    cardset = Qcardset.where(:cardset_id => 415)
    assert_equal 1, cardset.count
    term_count = cardset.first.term_count
    terms = Qcard.where(:cardset_id => 415)
    assert_equal term_count, terms.count 
  end

  test "Should like cardset" do
    cardset = Qcardset.where(:cardset_id => 415)
    assert_equal 0, cardset.count
    @controller = CardsetController.new
    @request.headers["setid"] = "quizlet_415"
    post :like, nil, @headers
    assert_response :success
    cardset = Qcardset.where(:cardset_id => 415)
    assert_equal 1, cardset.count
    term_count = cardset.first.term_count
    terms = Qcard.where(:cardset_id => 415)
    assert_equal term_count, terms.count
    assert_includes cardset.first.likes, @userid.to_s
  end

  test "Should return only popular cardsets (with likes)" do
    test_cardset1 = "quizlet_415"
    test_cardset2 = "quizlet_520"
    @controller = CardsetController.new
    # Import cardset 415
    @request.headers["setid"] = test_cardset1
    get :import, nil, @headers
    # Import cardset 420
    @request.headers["setid"] = test_cardset2
    get :import, nil, @headers
    post :like, nil, @headers
    assert_response :success
    # Get popular cardsets
    @request.headers["setid"] = nil
    get :popular, nil, @headers
    res_json = JSON.parse(response.body)
    # Should return only single cardset with like
    assert_equal Constants::RESULT_OK, res_json['result']
    assert_equal 1, res_json['data'].length
    assert_equal test_cardset2, res_json['data'][0]['gid']
  end

  test "Should put tag on cardset" do
    tag_id = "1"
    setid = 12048314
    gid = "quizlet_" + setid.to_s
    @controller = CardsetController.new
    @request.headers[Constants::HEADER_SETID] = gid
    @request.headers[Constants::HEADER_TAGID] = tag_id
    post :put_tag, nil, @headers
    assert_response :success
    cardsets = Qcardset.where('? = ANY(tags)', tag_id)
    assert_equal 1, cardsets.count
    assert_equal setid, cardsets.first.cardset_id
  end

  test "Should remove tag from cardset" do
    tag_id = "1"
    setid = 12048314
    gid = "quizlet_" + setid.to_s
    @controller = CardsetController.new
    @request.headers[Constants::HEADER_SETID] = gid
    @request.headers[Constants::HEADER_TAGID] = tag_id
    post :put_tag, nil, @headers
    assert_response :success
    post :drop_tag, nil, @headers
    assert_response :success
    cardsets = Qcardset.where('? = ANY(tags)', tag_id)
    assert_equal 0, cardsets.count
  end

  test "Should search cardset by tags" do
    tag_id1 = "1"
    tag_id2 = "2"
    tag_id3 = "3"
    setid1 = 12048314
    setid2 = 20511208
    setid3 = 21529589
    gid1 = "quizlet_" + setid1.to_s
    gid2 = "quizlet_" + setid2.to_s
    gid3 = "quizlet_" + setid3.to_s
    @controller = CardsetController.new

    @request.headers[Constants::HEADER_SETID] = gid1
    @request.headers[Constants::HEADER_TAGID] = tag_id1
    post :put_tag, nil, @headers
    assert_response :success

    @request.headers[Constants::HEADER_SETID] = gid2
    @request.headers[Constants::HEADER_TAGID] = tag_id2
    post :put_tag, nil, @headers
    assert_response :success

    tag_ids = tag_id2 + "," + tag_id3
    @request.headers[Constants::HEADER_SETID] = gid3
    @request.headers[Constants::HEADER_TAGID] = tag_ids
    post :put_tag, nil, @headers
    assert_response :success

    @request.headers[Constants::HEADER_TAGID] = tag_ids
    get :search, nil, @headers
    res_json = JSON.parse(response.body)
    assert_response :success
    assert_equal 1, res_json['data'].length
    assert_equal gid3, res_json['data'].first['gid']

    @request.headers[Constants::HEADER_TAGID] = tag_id2
    get :search, nil, @headers
    res_json = JSON.parse(response.body)
    assert_response :success
    assert_equal 2, res_json['data'].length

  end

  test "Should return tags" do
    @controller = CardsetController.new
    get :get_tags, nil, @headers
    res_json = JSON.parse(response.body)
    assert_response :success
    assert_equal 3, res_json['data'].length
  end

end
