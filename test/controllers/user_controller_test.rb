require 'rubygems'
require 'socket.io-client-simple'
require 'test_helper'

class UserControllerTest < ActionController::TestCase

  @@socket = SocketIO::Client::Simple.connect 'http://localhost:5002'

  def setup
    @request.headers["Content-Type"] = "application/json"
    @request.headers["Accept"] = "*/*"
    @request.headers[Constants::HEADER_SOCKETID] = @@socket.session_id
    @contact = "111111"
    @profile = {:email => "test@test.com", :phone => @contact, :name => "alex", :avatar => "http://google.com"}
    @profile2 = {:email => "test2@test.com", :phone => @contact2, :name => "alex2", :avatar => "http://google.com"}
  end

  def teardown
    Game.delete_all
    User.delete_all
    Card.delete_all
    Cardset.delete_all
  end

  def register(profile)
    @controller = UserController.new
    post :new, profile.to_json, @headers
    assert_response :success
    user_id = JSON.parse(@response.body)['data']['id']
    return JSON.parse(@response.body)['data']
  end

  def update(profile, userid)
    @controller = UserController.new
    @request.headers[Constants::HEADER_USERID] = userid
    put :update, profile.to_json
    return JSON.parse(@response.body)['data']
  end

  test "Should register new user" do
    user_id = register(@profile)['id']
    user = User.where(id: user_id).first
    assert_not_nil user
    assert_equal user.details, @profile.to_json
  end

  test "Should generate random nickname" do
    @profile[:name] = ""
    user_name = register(@profile)['name']
    assert_not_nil user_name
    assert user_name.length > 0
  end

  test "Should generate random avatar" do
    @profile[:avatar] = ""
    avatar = register(@profile)['avatar']
    assert_not_nil avatar
    assert avatar.length > 0
  end

  test "Should update name" do
    user_id = register(@profile)['id']
    @profile[:name] = "name2"
    assert_equal @profile[:name], update(@profile, user_id)['name']
  end

  test "Should prevent duplicate names" do
    user_id1 = register(@profile)['id']
    user_id2 = register(@profile2)['id']
    @profile[:name] = @profile2[:name]
    update(@profile, user_id1)
    
    assert_equal Constants::RESULT_ERROR, JSON.parse(@response.body)['result']
  end

  test "Should return user by id" do
    user_id = register(@profile)['id']
    @request.headers[Constants::HEADER_USERID] = user_id
    get :get
    assert_equal user_id, JSON.parse(@response.body)['data']['id']
    assert_equal @profile[:name], JSON.parse(@response.body)['data']['name']
  end

  test "Should return user by name" do
    user_id1 = register(@profile)['id']
    user_id2 = register(@profile2)['id']
    @request.headers[Constants::HEADER_USERID] = user_id1
    @request.headers[Constants::HEADER_USERNAME] = @profile2[:name]
    get :get
    assert_equal user_id2, JSON.parse(@response.body)['data']['id']
    assert_equal @profile2[:name], JSON.parse(@response.body)['data']['name']
  end

end
