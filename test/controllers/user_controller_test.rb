require 'rubygems'
require 'socket.io-client-simple'
require 'test_helper'

class UserControllerTest < ActionController::TestCase

  def setup
    @socket = SocketIO::Client::Simple.connect 'http://localhost:5001'
    @request.headers["Content-Type"] = "application/json"
    @request.headers["Accept"] = "*/*"
    @contact = "111111"
    @profile = {:email => "test@test.com", :phone => @contact, :name => "alex", :avatar => "http://google.com"}
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

  test "Should register new user" do
    user_id = register(@profile)['id']
    user = User.where(id: user_id).first
    assert_not_nil user
    assert_equal user.details, @profile.to_json
  end

  test "Should generate random nickname" do
    @profile[:name] = nil
    user_name = register(@profile)['details']['name']
    assert_not_nil user_name
  end

end
