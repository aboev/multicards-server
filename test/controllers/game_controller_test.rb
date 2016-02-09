require 'rubygems'
require 'socket.io-client-simple'
require 'test_helper'

class GameControllerTest < ActionController::TestCase
  
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

  test "Should return pending game list" do
    @controller = GameController.new
    get :get, nil, @headers
    assert_response :success 
    games = JSON.parse(@response.body)['data']
    assert_equal 1, games.length
    assert_equal games(:one).id, games[0]["id"]
  end

end
