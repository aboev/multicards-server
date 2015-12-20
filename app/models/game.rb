require 'protocol'

class Game < ActiveRecord::Base

  STATUS_SEARCHING_PLAYERS = 0
  STATUS_IN_PROGRESS = 1
  STATUS_COMPLETED = 2

  PLAYER_STATUS_WAITING = "player_waiting"
  PLAYER_STATUS_THINKING = "player_thinking"
  PLAYER_STATUS_ANSWERED = "player_answered"

  QUESTIONS_PER_GAME = 25

  def init(setid)
    game_details = {Constants::JSON_GAME_STATUS => Game::STATUS_SEARCHING_PLAYERS,
	Constants::JSON_GAME_QUESTIONCNT => 0,
	Constants::JSON_GAME_PROFILES => {},
	Constants::JSON_GAME_PLAYERS => {}}
    self.status = Game::STATUS_SEARCHING_PLAYERS
    self.details = game_details.to_json
    self.setid = setid
    self.save
  end

  def start_game
    details_json = JSON.parse(self.details)
    if (details_json[Constants::JSON_GAME_PLAYERS].length > 1 )
      details_json[Constants::JSON_GAME_STATUS] = STATUS_IN_PROGRESS
      self.status = STATUS_IN_PROGRESS
      self.details = details_json.to_json
      self.save

      msg_to = details_json[Constants::JSON_GAME_PLAYERS].keys
      msg_type = Constants::SOCK_MSG_TYPE_GAME_START
      msg_body = details_json
      message = Protocol.make_msg(msg_to, msg_type, msg_body)
      $redis.publish Constants::SOCK_CHANNEL, message
      next_question
    end
  end

  def join_player(user)
    details_json = JSON.parse(self.details)
    details_json[Constants::JSON_GAME_PROFILES][user.socket_id] = user.get_details
    details_json[Constants::JSON_GAME_PLAYERS][user.socket_id] = Game::PLAYER_STATUS_WAITING
    self.details = details_json.to_json
    self.save
  end

  def next_question
   details = JSON.parse(self.details)
   ready_players = self.get_ready_players_count
   total_players = details[Constants::JSON_GAME_PLAYERS].length
   game_status = details[Constants::JSON_GAME_STATUS]
   question_id = details[Constants::JSON_GAME_QUESTIONCNT] + 1
   if ( (game_status == Game::STATUS_IN_PROGRESS) and ( ready_players == total_players ) )

     question = Question.make_random(Question::QTYPE_MULTI_CHOICE, self.setid, question_id)
     if ( rand(100) > 110 )
       question = Question.make_random(Question::QTYPE_DIRECT_INPUT, self.setid, question_id)
     end

     msg_to = details[Constants::JSON_GAME_PLAYERS].keys
     msg_type = Constants::SOCK_MSG_TYPE_NEW_QUESTION
     msg_body = question
     message = Protocol.make_msg(msg_to, msg_type, msg_body)
     details[Constants::JSON_GAME_CURQUESTION] = question
     details[Constants::JSON_GAME_QUESTIONCNT] = details[Constants::JSON_GAME_QUESTIONCNT] + 1

     Hash.new.merge(details[Constants::JSON_GAME_PLAYERS]).keys.each do |player_id|
       details[Constants::JSON_GAME_PLAYERS][player_id] = PLAYER_STATUS_THINKING
     end

     self.details = details.to_json
     save

     $redis.publish Constants::SOCK_CHANNEL, message
   end
  end

  def end_game
    details = JSON.parse(self.details)
    players = details[Constants::JSON_GAME_PLAYERS]
    message_to = players.keys
    message = {Constants::JSON_SOCK_MSG_TO => message_to, Constants::JSON_SOCK_MSG_TYPE => Constants::SOCK_MSG_TYPE_GAME_END, Constants::JSON_SOCK_MSG_BODY => self.id}.to_json
    $redis.publish Constants::SOCK_CHANNEL, message
  end

  def self.find_by_socket_id(socket_id)
    res = []
    games = Game.all
    games.each do |game|
      game_details = JSON.parse(game.details)
      players = game_details[Constants::JSON_GAME_PLAYERS]
      players.each do |sockid, status|
        if ( sockid == socket_id )
          res << game
        end
      end
    end
    return res
  end

  def get_ready_players_count
    game_details = JSON.parse(self.details)
    players = game_details[Constants::JSON_GAME_PLAYERS]
    ready_players = 0
    players.each do |sockid, status|
      if ( players[sockid] == Game::PLAYER_STATUS_WAITING )
        ready_players = ready_players + 1
      end
    end
    return ready_players
  end

  def get_players_count
    game_details = JSON.parse(game.details)
    players = game_details[Constants::JSON_GAME_PLAYERS]
    return players.length
  end

end
