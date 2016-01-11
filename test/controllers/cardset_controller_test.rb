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
    Game.delete_all
    User.delete_all
    Card.delete_all
    Cardset.delete_all
    Qcardset.delete_all
    Qcard.delete_all
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
    test_cardset1 = 415
    test_cardset2 = 520
    @controller = CardsetController.new
    # Import cardset 415
    @request.headers["setid"] = "quizlet_" + test_cardset1.to_s
    get :import, nil, @headers
    # Import cardset 420
    @request.headers["setid"] = "quizlet_" + test_cardset2.to_s
    get :import, nil, @headers
    post :like, nil, @headers
    assert_response :success
    # Get popular cardsets
    @request.headers["setid"] = nil
    get :popular, nil, @headers
    res_json = JSON.parse(response.body)
    # Should return only single cardset with like
    assert_equal Constants::RESULT_OK, res_json['result']
    assert_equal 1, JSON.parse(res_json['data']).length
    assert_equal test_cardset2, JSON.parse(res_json['data'])[0]['cardset_id']
  end

end