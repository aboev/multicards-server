require 'protocol'
require 'gameplay_data'

class Game < ActiveRecord::Base

  STATUS_SEARCHING_PLAYERS = 0
  STATUS_WAITING_OPPONENT = 1
  STATUS_IN_PROGRESS = 2
  STATUS_COMPLETED = 3

  PLAYER_STATUS_WAITING = "player_waiting"
  PLAYER_STATUS_THINKING = "player_thinking"
  PLAYER_STATUS_ANSWERED = "player_answered"

  QUESTIONS_PER_GAME = 25

  def init(setid, rnd_opp)
    status = Game::STATUS_SEARCHING_PLAYERS
    if rnd_opp == false
      status = Game::STATUS_WAITING_OPPONENT
    end
    gameplay_data = GameplayData.new(setid)
    game_details = {Constants::JSON_GAME_STATUS => status,
	Constants::JSON_GAME_QUESTIONCNT => 0,
	Constants::JSON_GAME_PROFILES => {},
	Constants::JSON_GAME_PLAYERS => {},
	Constants::JSON_GAME_SCORES => {},
	Constants::JSON_GAME_PREVQST => {},
        Constants::JSON_GAME_GAMEPLAYDATA => gameplay_data.to_json}
    self.status = status
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
    details_json[Constants::JSON_GAME_SCORES][user.socket_id] = 0
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

      question = details[Constants::JSON_GAME_GAMEPLAYDATA]['questions'][question_id - 1]

      msg_to = details[Constants::JSON_GAME_PLAYERS].keys
      msg_type = Constants::SOCK_MSG_TYPE_NEW_QUESTION
      msg_body = question
      msg_extra = self.get_scores
      message = Protocol.make_msg_extra(msg_to, msg_type, msg_body, msg_extra)
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

  def stop_game
    details = JSON.parse(self.details)
    players = details[Constants::JSON_GAME_PLAYERS]
    message_to = players.keys
    message = {Constants::JSON_SOCK_MSG_TO => message_to, Constants::JSON_SOCK_MSG_TYPE => Constants::SOCK_MSG_TYPE_GAME_STOP, Constants::JSON_SOCK_MSG_BODY => self.id}.to_json
    $redis.publish Constants::SOCK_CHANNEL, message
  end

  def end_game
    details = JSON.parse(self.details)
    players = details[Constants::JSON_GAME_PLAYERS]
    message_to = players.keys

    winner_details = nil
    scores = {}
    winner = get_winner
    if (winner != nil)
      winner_details = winner.get_details
      winner_socket_id = winner.socket_id
      self.get_scores.each do |socket_id, score|
        player = User.where(:socket_id => socket_id).first
        if player != nil
          if player.socket_id == winner_socket_id
            player.score = player.score + Constants::SCORE_PER_WIN
            player.save
          end
          scores[socket_id] = player.score
        else
          scores[socket_id] = nil
        end
      end
    end
    msg_body = {:id => self.id, :winner => winner_details, :scores => scores}
 
    message = {Constants::JSON_SOCK_MSG_TO => message_to, Constants::JSON_SOCK_MSG_TYPE => Constants::SOCK_MSG_TYPE_GAME_END, Constants::JSON_SOCK_MSG_BODY => msg_body}.to_json
    $redis.publish Constants::SOCK_CHANNEL, message
  end

  def self.find_by_socket_id(socket_id, status)
    res = []
    games = Game.all
    if status != nil
      games = Game.where(:status => status)
    end
    games.each do |game|
      game_details = JSON.parse(game.details)
      players = game_details[Constants::JSON_GAME_PLAYERS]
      if players[socket_id] != nil
        res << game
      end
    end
    return res
  end

  def increase_player_score(socket_id)
    game_details = JSON.parse(self.details)
    score = game_details[Constants::JSON_GAME_SCORES][socket_id]
    game_details[Constants::JSON_GAME_SCORES][socket_id] = score + 1
    return game_details[Constants::JSON_GAME_SCORES]
  end

  def set_player_status(socket_id, status)
    game_details = JSON.parse(self.details)
    game_details[Constants::JSON_GAME_PLAYERS][socket_id] = status
    self.details = game_details.to_json
    self.save
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
    game_details = JSON.parse(self.details)
    players = game_details[Constants::JSON_GAME_PLAYERS]
    return players.length
  end

  def get_scores
    game_details = JSON.parse(self.details)
    scores = game_details[Constants::JSON_GAME_SCORES]
    return scores
  end

  def get_winner
    scores = get_scores
    winner_id = scores.keys.first
    max_score = scores.values.first
    scores.each do |id, score|
      if score > max_score
        max_score = score
        winner_id = id
      end
    end
    winner = User.where(:socket_id => winner_id).first
  end

end
