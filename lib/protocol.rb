require 'question'

class Protocol

  def self.msg_user_status_update(id_from, msg_type, msg_body)
    new_status = msg_body
    Rails.logger.info("Player status update request")
    games = Game.find_by_socket_id(id_from)
    games.each do |game|
      game_details = JSON.parse(game.details)
      game_details[Constants::JSON_GAME_PLAYERS][id_from] = new_status
      game.details = game_details.to_json
      game.save
      players_count = game_details[Constants::JSON_GAME_PLAYERS].length
      questions_count = game_details[Constants::JSON_GAME_QUESTIONCNT]
      if (players_count == game.get_ready_players_count())
        if (questions_count >= Game::QUESTIONS_PER_GAME)
          game.end_game
          game.destroy
        else
          game.next_question
        end
      end
    end
  end

  def self.msg_socket_close(id_from, msg_type, msg_body)
    puts id_from
    socket_id = msg_body
    games = Game.find_by_socket_id(socket_id)
    games.each do |game|
      puts game.id
      game.end_game
      game.destroy
    end
  end

  def self.msg_announce_userid(id_from, msg_type, msg_body)
    userid = msg_body
    user = User.find_by_id(msg_body)
    user.socket_id = id_from
    user.save
  end

  def self.msg_user_answered(id_from, msg_type, msg_body)
    game = Game.find_by_socket_id(id_from).first
    game_details = JSON.parse(game.details)

    user_answer = msg_body
    correct_answer = game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_ANSWER_ID]
    question_status = game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_STATUS]
    question_id = game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_ID]
    answer_accepted = true
    if ((question_status == Question::QSTATUS_RIGHT_ANSWER) and (user_answer == correct_answer))
      msg_to = [id_from]
      msg_type = Constants::SOCK_MSG_TYPE_ANSWER_REJECTED
      msg_body = question_id
      message = Protocol.make_msg(msg_to, msg_type, msg_body)
      $redis.publish Constants::SOCK_CHANNEL, message
      answer_accepted = false
    elsif ((question_status == Question::QSTATUS_NO_ANSWER))
      msg_to = [id_from]
      msg_type = Constants::SOCK_MSG_TYPE_ANSWER_ACCEPTED
      msg_body = question_id
      message = Protocol.make_msg(msg_to, msg_type, msg_body)
      $redis.publish Constants::SOCK_CHANNEL, message
      if (user_answer == correct_answer)
        game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_STATUS] = Question::QSTATUS_RIGHT_ANSWER
      else
        game_details[Constants::JSON_GAME_CURQUESTION][Constants::JSON_QST_STATUS] = Question::QSTATUS_WRONG_ANSWER
      end
    end

    game_details[Constants::JSON_GAME_PLAYERS][id_from] = Game::PLAYER_STATUS_ANSWERED
    game.details = game_details.to_json
    game.save

    if answer_accepted == true
      msg_to = game_details[Constants::JSON_GAME_PLAYERS].keys
      msg_to.delete(id_from)
      message = Protocol.make_msg(msg_to, msg_type, user_answer) 
      $redis.publish Constants::SOCK_CHANNEL, message  
      #players = game_details[Constants::JSON_GAME_PLAYERS].keys.except(id_from)
    end
  end

  def self.parse_msg(msg_json)
    id_from = msg_json[Constants::JSON_SOCK_MSG_FROM]
    msg_type = msg_json[Constants::JSON_SOCK_MSG_TYPE]
    msg_body = msg_json[Constants::JSON_SOCK_MSG_BODY]

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
    end
  
    res = { :result => Constants::RESULT_OK }

  end

  def self.make_msg(id_to, msg_type, msg_body)
    message = {Constants::JSON_SOCK_MSG_TO => id_to, Constants::JSON_SOCK_MSG_TYPE => msg_type, Constants::JSON_SOCK_MSG_BODY => msg_body}.to_json
    return message
  end

  def self.make_question(question, options, answer_id, question_id)
    question = {Constants::JSON_QST_QUESTION => question,
        Constants::JSON_QST_OPTIONS => options,
        Constants::JSON_QST_ANSWER_ID => answer_id,
	Constants::JSON_QST_ID => question_id,
	Constants::JSON_QST_STATUS => Question::QSTATUS_NO_ANSWER}
  end

end
