ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all
  self.use_transactional_fixtures = false
  # Add more helper methods to be used by all tests here...

  def register(profile)
    post '/user', profile.to_json, @headers
    assert_response :success
    user_id = JSON.parse(@response.body)['data']['id']
  end

  def new_game(userid, socketid)
    @headers[Constants::HEADER_USERID] = userid
    @headers[Constants::HEADER_SOCKETID] = socketid
    post '/game', nil, @headers
    game_id = JSON.parse(@response.body)['data']['id']
  end

  def update_client_status(socket, status)
    msg_type = Constants::SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE
    msg_body = status
    msg = Protocol.make_msg(nil, msg_type, msg_body)
    socket.emit :message, msg
  end

  def player_answer(socket, answer_id, id_to)
    msg_type = Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED
    msg_body = answer_id
    msg = Protocol.make_msg(id_to, msg_type, msg_body)
    socket.emit :message, msg
  end

  def quit_game(socket)
    msg_type = Constants::SOCK_MSG_TYPE_QUIT_GAME
    msg_body = socket.session_id
    msg = Protocol.make_msg(nil, msg_type, msg_body)
    socket.emit :message, msg
  end

  def filter(list, msg_type)
    res = []
    list.each do |msg|
      if msg[Constants::JSON_SOCK_MSG_TYPE] == msg_type
        res << msg
      end
    end
    return res
  end

end
