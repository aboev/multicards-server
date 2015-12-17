require 'constants'
require 'protocol'
module TestUtils

  def register(profile)
    @controller = UserController.new
    post :new, profile.to_json
    assert_response :success
    user_id = JSON.parse(@response.body)['data']['id']
  end

  def new_game(userid, socketid)
    @controller = GameController.new
    @request.headers[Constants::HEADER_USERID] = userid
    @request.headers[Constants::HEADER_SOCKETID] = socketid
    post :new
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
