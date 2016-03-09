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
    @@sock1_msg_list = []
  end

  def teardown
    clear_db
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

  test "Should update pushid" do
    user_id = register(@profile)['id']
    pushid = "JKSHBVNKSFJBIOWRNBVLKJSNSLKFVBJLSKMFBLKSFJVCM<XZLCJSLFKJBJFSHMCXNZCHBWUORJFSKLMVCLKXZJKH"
    @profile[:pushid] = pushid
    update(@profile, user_id)
    user = User.where(:pushid => pushid).first
    assert_equal user_id, user.id
  end

  test "Should update deviceid" do
    user_id = register(@profile)['id']
    deviceid = "AAFFMDKVJDNCJDJV"
    @profile[:deviceid] = deviceid
    update(@profile, user_id)
    user = User.where(:deviceid => deviceid).first
    assert_equal user_id, user.id
  end

  test "Should prevent duplicate deviceid" do
    user_id1 = register(@profile)['id']
    user_id2 = register(@profile2)['id']
    deviceid = "AAFFMDKVJDNCJDJV"
    @profile[:deviceid] = deviceid
    @profile2[:deviceid] = deviceid
    update(@profile, user_id1)
    update(@profile, user_id2)
    assert_equal Constants::RESULT_ERROR, JSON.parse(@response.body)['result']
  end

  test "Should return existing user with deviceid" do
    user_id1 = register(@profile)['id']
    deviceid = "AAFFMDKVJDNCJDJV"
    @profile[:deviceid] = deviceid
    update(@profile, user_id1)
    @profile2[:deviceid] = deviceid
    user_id2 = register(@profile2)['id']
    assert_equal user_id1, user_id2
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

  test "Should check name availability" do
    userid = register(@profile)['id']
    register(@profile2)

    # Announce socket id
    @request.headers[Constants::HEADER_USERID] = userid
    @request.headers[Constants::HEADER_SOCKETID] = @@socket.session_id
    get :get
    
    # Check available name
    msg_type = Constants::SOCK_MSG_TYPE_CHECK_NAME
    name = "name3"
    msg = Protocol.make_msg(nil, msg_type, name)
    @@socket.emit :message, msg    
    sleep(1)
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_CHECK_NAME).length
    assert_equal true, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_CHECK_NAME).first['msg_body'][name]
    @@sock1_msg_list = []

    # Check current name
    name = @profile[:name]
    msg = Protocol.make_msg(nil, msg_type, name)
    @@socket.emit :message, msg    
    sleep(1)
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_CHECK_NAME).length
    assert_equal true, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_CHECK_NAME).first['msg_body'][name]
    @@sock1_msg_list = []

    # Check existing name
    name = @profile2[:name]
    msg = Protocol.make_msg(nil, msg_type, name)
    @@socket.emit :message, msg
    sleep(1)
    assert_equal 1, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_CHECK_NAME).length
    assert_equal false, filter(@@sock1_msg_list, Constants::SOCK_MSG_TYPE_CHECK_NAME).first['msg_body'][name]
  end

  test "Should list user profiles by id" do
    user_id1 = register(@profile)['id']
    user_id2 = register(@profile2)['id']
    @request.headers[Constants::HEADER_USERID] = user_id1
    @request.headers[Constants::HEADER_IDS] = user_id1.to_s + "," + user_id2.to_s
    get :list
    assert_equal 2, JSON.parse(@response.body)['data'].length
  end

  test "Should return botlist" do
    user_id = register(@profile)['id']
    @request.headers[Constants::HEADER_USERID] = user_id
    get :get_bots
    assert_equal 1, JSON.parse(@response.body)['data'].length
    assert_equal "bot", JSON.parse(@response.body)['data'][0]['name']
  end

  @@socket.on :event do |msg|
    msg_json = JSON.parse(msg)
    @@sock1_msg_list << msg_json
  end

end
