require 'question'
require 'gameplay_manager'

class Protocol

  def self.msg_user_status_update(id_from, msg_type, msg_body)
    status = msg_body
    GameplayManager.status_update(id_from, status)
  end

  def self.msg_socket_close(id_from, msg_type, msg_body)
    puts id_from
    socket_id = msg_body
    games = Game.find_by_socket_id(socket_id, nil)
    games.each do |game|
      puts game.id
      game.stop_game
      game.destroy
    end
    user = User.find_by_socket_id(socket_id)
    if user != nil
      user.status = Constants::STATUS_OFFLINE
      user.save
    end
  end

  def self.msg_announce_userid(id_from, msg_type, msg_body)
    userid = msg_body
    user = User.find_by_id(msg_body)
    user.socket_id = id_from
    user.save
  end

  def self.msg_user_answered(id_from, msg_type, msg_body)
    game = Game.find_by_socket_id(id_from, nil).first
    game_details = JSON.parse(game.details)

    user_answer = msg_body
    correct_answer = game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_ANSWER_ID]
    question_status = game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_STATUS]
    question_id = game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_ID]

    answer_accepted = true
    msg_type = Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED
    if ((question_status == Question::QSTATUS_RIGHT_ANSWER) and (user_answer.to_s == correct_answer.to_s))
      # Question already answered correctly -> reject correct answer
      msg_type = Constants::SOCK_MSG_TYPE_ANSWER_REJECTED
      answer_accepted = false
    else
      # Question not answered correctly yet -> accept any answer
      if (user_answer.to_s == correct_answer.to_s)
        game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_STATUS] = Question::QSTATUS_RIGHT_ANSWER
        game_details[Constants::JSON_GAME_SCORES] = game.increase_player_score(id_from)
      else
        game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_STATUS] = Question::QSTATUS_WRONG_ANSWER
      end
    end
    msg_to = [id_from]
    msg_body = question_id
    message = Protocol.make_msg(msg_to, msg_type, msg_body)
    $redis.publish Constants::SOCK_CHANNEL, message

    if (game_details[Constants::JSON_GAME_PLAYERS][id_from] != Game::PLAYER_STATUS_WAITING)
      game_details[Constants::JSON_GAME_PLAYERS][id_from] = Game::PLAYER_STATUS_ANSWERED
    end
    game.details = game_details.to_json
    game.save

    if answer_accepted == true
      msg_to = game_details[Constants::JSON_GAME_PLAYERS].keys
      msg_type = Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED
      msg_to.delete(id_from)
      message = Protocol.make_msg(msg_to, msg_type, user_answer) 
      $redis.publish Constants::SOCK_CHANNEL, message  
      #players = game_details[Constants::JSON_GAME_PLAYERS].keys.except(id_from)
    end
  end

  def self.msg_check_name(id_from, msg_type, name)
    user = User.find_by_name(name)

    msg_to = [id_from]
    msg_type = Constants::SOCK_MSG_TYPE_CHECK_NAME
    name_avail = false
    if ((user == nil) or (user.socket_id == id_from))
      name_avail = true
    end
    
    msg_body = {name => name_avail}
    message = Protocol.make_msg(msg_to, msg_type, msg_body)
    $redis.publish Constants::SOCK_CHANNEL, message
  end

  def self.msg_game_invite(id_from, opponent_name, game_id)
    GameplayManager.invite_user(id_from, opponent_name, game_id)
  end

  def self.msg_invite_accepted(id_from, game_id)
    GameplayManager.accept_invitation(id_from, game_id)
  end

  def self.msg_invite_rejected(id_from, game_id)
    GameplayManager.reject_invitation(id_from, game_id)
  end

  def self.msg_check_network(id_from, msg_type, msg_body)
    msg_to = [id_from]
    message = Protocol.make_msg(msg_to, msg_type, msg_body)
    $redis.publish Constants::SOCK_CHANNEL, message
  end

  def self.msg_set_gid(id_from, msg_type, msg_body, msg_extra)
    gid = msg_body
    game_id = msg_extra
    GameplayManager.change_gid(id_from, game_id, gid)
  end

  def self.msg_confirm(id_to, msg_id)
    msg_to = [id_to]
    msg_body = msg_id
    msg_type = Constants::SOCK_MSG_TYPE_CONFIRM
    message = Protocol.make_msg(msg_to, msg_type, msg_body)
    $redis.publish Constants::SOCK_CHANNEL, message
  end

  def self.parse_msg(msg_json)
    id_from = msg_json[Constants::JSON_SOCK_MSG_FROM]
    msg_type = msg_json[Constants::JSON_SOCK_MSG_TYPE]
    msg_body = msg_json[Constants::JSON_SOCK_MSG_BODY]
    msg_extra = msg_json[Constants::JSON_SOCK_MSG_EXTRA]
    msg_id = msg_json[Constants::JSON_SOCK_MSG_ID]

    if (msg_body == nil)
      res = {   :result => Constants::RESULT_ERROR,
                :code => Constants::ERROR_BODY_FORMAT,
                :message => Constants::MSG_BODY_FORMAT }
      return res
    end

    if (msg_type == Constants::SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE)
      self.msg_user_status_update(id_from, msg_type, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_SOCKET_CLOSE)
      self.msg_socket_close(id_from, msg_type, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_QUIT_GAME)
      self.msg_socket_close(id_from, msg_type, id_from)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_PLAYER_ANSWERED)
      self.msg_user_answered(id_from, msg_type, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_ANNOUNCE_USERID)
      self.msg_announce_userid(id_from, msg_type, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_CHECK_NAME)
      self.msg_check_name(id_from, msg_type, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_CHECK_NETWORK)
      self.msg_check_network(id_from, msg_type, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_GAME_INVITE)
      self.msg_game_invite(id_from, msg_body, msg_extra)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED)
      self.msg_invite_accepted(id_from, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_INVITE_REJECTED)
      self.msg_invite_rejected(id_from, msg_body)
    elsif (msg_type == Constants::SOCK_MSG_TYPE_SET_GID)
      self.msg_set_gid(id_from, msg_type, msg_body, msg_extra)
    end

    self.msg_confirm(id_from, msg_id) if msg_id != nil
  
    res = { :result => Constants::RESULT_OK }

  end

  def self.make_msg(id_to, msg_type, msg_body)
    message = {Constants::JSON_SOCK_MSG_TO => id_to, Constants::JSON_SOCK_MSG_TYPE => msg_type, Constants::JSON_SOCK_MSG_BODY => msg_body}.to_json
    return message
  end

  def self.make_msg_extra(id_to, msg_type, msg_body, msg_extra)
    message = {Constants::JSON_SOCK_MSG_TO => id_to, Constants::JSON_SOCK_MSG_TYPE => msg_type, Constants::JSON_SOCK_MSG_BODY => msg_body, Constants::JSON_SOCK_MSG_EXTRA => msg_extra}.to_json
    return message
  end

  def self.make_question(question, options, answer_id, question_id)
    question = {Constants::JSON_QST_QUESTION => question,
        Constants::JSON_QST_OPTIONS => options,
        Constants::JSON_QST_ANSWER_ID => answer_id,
	Constants::JSON_QST_ID => question_id,
	Constants::JSON_QST_STATUS => Question::QSTATUS_NO_ANSWER}
  end

  def self.make_question_with_images(question, options, answer_id, question_id, images)
    question = {Constants::JSON_QST_QUESTION => question,
        Constants::JSON_QST_OPTIONS => options,
        Constants::JSON_QST_IMAGES => images,
        Constants::JSON_QST_ANSWER_ID => answer_id,
        Constants::JSON_QST_ID => question_id,
        Constants::JSON_QST_STATUS => Question::QSTATUS_NO_ANSWER}
  end

end
