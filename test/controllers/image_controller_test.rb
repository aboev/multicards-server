require 'rubygems'
require 'socket.io-client-simple'
require 'test_helper'
require 'net/http'

class UserControllerTest < ActionController::TestCase

  @@socket = SocketIO::Client::Simple.connect 'http://localhost:5002'

  def setup
    @request.headers["Content-Type"] = "application/json"
    @request.headers["Accept"] = "*/*"
    @contact = "111111"
    @profile = {:email => "test@test.com", :phone => @contact, :name => "alex", :avatar => "http://google.com"}
    @img_filename = "/image.png"
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

  test "Should upload image" do
    #Register user
    user_id = register(@profile)['id']

    #Upload image
    @controller = UploadController.new
    @request.headers[Constants::HEADER_USERID] = user_id
    @request.headers[Constants::HEADER_SOCKETID] = @@socket.session_id 
   
    img_filename = "/image.png" 
    file = fixture_file_upload(img_filename, 'image/png')

    post :upload, { name: img_filename, image: file}
    assert_equal JSON.parse(@response.body)['result'], Constants::RESULT_OK
    image_url = JSON.parse(@response.body)['data']

    #Check existing db entry
    user = User.where(:id => user_id).first
    assert_not_nil user.get_details["avatar"]
    assert_equal image_url, user.get_details["avatar"]

  end

end
