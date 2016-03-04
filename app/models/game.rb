require 'protocol'
require 'gameplay_data'
require 'gameplay_manager'
require 'utils'

class Game < ActiveRecord::Base

  STATUS_SEARCHING_PLAYERS = 0
  STATUS_WAITING_OPPONENT = 1
  STATUS_IN_PROGRESS = 2
  STATUS_COMPLETED = 3
  STATUS_INTERRUPTED = 4

  PLAYER_STATUS_PENDING = "player_pending"
  PLAYER_STATUS_WAITING = "player_waiting"
  PLAYER_STATUS_THINKING = "player_thinking"
  PLAYER_STATUS_ANSWERED = "player_answered"

  QUESTIONS_PER_GAME = 25

  def init(gid, rnd_opp)
    setid = Utils.parse_gid(gid)[1]
    status = Game::STATUS_SEARCHING_PLAYERS
    if rnd_opp == false
      status = Game::STATUS_WAITING_OPPONENT
    end
    gameplay_data = GameplayData.new(setid)
    game_details = {Constants::JSON_GAME_STATUS => status,
	Constants::JSON_GAME_GID => gid,
	Constants::JSON_GAME_QUESTIONCNT => 0,
	Constants::JSON_GAME_PROFILES => {},
	Constants::JSON_GAME_PLAYERS => {},
	Constants::JSON_GAME_SCORES => {},
	Constants::JSON_GAME_PREVQST => {},
        Constants::JSON_GAME_BONUSES => {},
        Constants::JSON_GAME_TOTAL_QUESTIONS => gameplay_data.to_json[:questions].length}
    self.status = status
    self.details = game_details.to_json
    self.gameplay_data = gameplay_data.to_json.to_json
    self.setid = setid
    self.save

    game_details[Constants::JSON_GAME_ID] = self.id
    self.details = game_details.to_json
    self.save
  end

  def start_game
    details_json = JSON.parse(self.details)
    if (details_json[Constants::JSON_GAME_PLAYERS].length > 1 )
      details_json[Constants::JSON_GAME_STATUS] = STATUS_IN_PROGRESS
      details_json[Constants::JSON_GAME_ID] = self.id
      self.status = STATUS_IN_PROGRESS
      self.details = details_json.to_json
      self.save

      GameplayManager.start_game(self)

      msg_to = details_json[Constants::JSON_GAME_PLAYERS].keys
      msg_type = Constants::SOCK_MSG_TYPE_GAME_START
      msg_body = details_json
      message = Protocol.make_msg(msg_to, msg_type, msg_body)
      $redis.publish APP_CONFIG['sock_channel'], message
      next_question

      GameLog.log(self)
    end
  end

  def join_player(user, status)
    status = Game::PLAYER_STATUS_WAITING if status == nil
    details_json = JSON.parse(self.details)
    if (details_json[Constants::JSON_GAME_PLAYERS].length == 0)
      self.player1_id = user.id
      self.player1_status = status
    else
      self.player2_id = user.id
      self.player2_status = status
    end
    self.save
    update_player(user, status)
  end

  def update_player(player, status)
    details_json = JSON.parse(self.details)
    old_socketid = nil
    if ((self.player1_id == player.id) and (self.player1_socketid != player.socket_id))
      old_socketid = self.player1_socketid
      self.player1_socketid = player.socket_id
    elsif ((self.player2_id == player.id) and (self.player2_socketid != player.socket_id))
      old_socketid = self.player2_socketid
      self.player2_socketid = player.socket_id
    end
    if ((old_socketid != nil) and (old_socketid.length > 0))
      details_json[Constants::JSON_GAME_PROFILES].delete(old_socketid)
      details_json[Constants::JSON_GAME_PLAYERS].delete(old_socketid)
      details_json[Constants::JSON_GAME_SCORES].delete(old_socketid)
      details_json[Constants::JSON_GAME_BONUSES].delete(old_socketid)
    end
    details_json[Constants::JSON_GAME_PROFILES][player.socket_id] = player.get_details
    details_json[Constants::JSON_GAME_PLAYERS][player.socket_id] = status
    details_json[Constants::JSON_GAME_SCORES][player.socket_id] = 0
    details_json[Constants::JSON_GAME_BONUSES][player.socket_id] = []
    self.details = details_json.to_json
    self.save
  end

  def set_player_status(socket_id, status)
    self.update(:player1_status => status) if player1_socketid == socket_id
    self.update(:player2_status => status) if player2_socketid == socket_id
    game_details = JSON.parse(self.details)
    game_details[Constants::JSON_GAME_PLAYERS][socket_id] = status
    self.details = game_details.to_json
    self.save
  end

  def next_question
    details = JSON.parse(self.details)
    gameplay_data = JSON.parse(self.gameplay_data)
    ready_players = self.get_ready_players_count
    total_players = details[Constants::JSON_GAME_PLAYERS].length
    game_status = details[Constants::JSON_GAME_STATUS]
    question_id = details[Constants::JSON_GAME_QUESTIONCNT] + 1
    if ( (game_status == Game::STATUS_IN_PROGRESS) and ( ready_players == total_players ) )

      #question = Question.make_random(Question::QTYPE_MULTI_CHOICE, self.setid, question_id)
      #if ( rand(100) > 110 )
      #  question = Question.make_random(Question::QTYPE_DIRECT_INPUT, self.setid, question_id)
      #end

      question = gameplay_data['questions'][question_id - 1]

      msg_to = details[Constants::JSON_GAME_PLAYERS].keys
      msg_type = Constants::SOCK_MSG_TYPE_NEW_QUESTION
      msg_body = question
      msg_extra = self.get_scores
      message = Protocol.make_msg_extra(msg_to, msg_type, msg_body, msg_extra)
      details[Constants::JSON_GAME_CURQUESTION] = question
      details[Constants::JSON_GAME_QUESTIONCNT] = question_id

      Hash.new.merge(details[Constants::JSON_GAME_PLAYERS]).keys.each do |player_id|
        details[Constants::JSON_GAME_PLAYERS][player_id] = PLAYER_STATUS_THINKING
        set_player_status(player_id, PLAYER_STATUS_THINKING)
      end

      self.details = details.to_json
      save

      $redis.publish APP_CONFIG['sock_channel'], message
    end
  end

  def stop_game
    details = JSON.parse(self.details)

    self.status = STATUS_INTERRUPTED
    self.save
    GameLog.log(self)

    players = details[Constants::JSON_GAME_PLAYERS]
    message_to = players.keys
    message = {Constants::JSON_SOCK_MSG_TO => message_to, Constants::JSON_SOCK_MSG_TYPE => Constants::SOCK_MSG_TYPE_GAME_STOP, Constants::JSON_SOCK_MSG_BODY => self.id}.to_json
    $redis.publish APP_CONFIG['sock_channel'], message
  end

  def end_game
    details = JSON.parse(self.details)
    players = details[Constants::JSON_GAME_PLAYERS]
    gid = details[Constants::JSON_GAME_GID]
    message_to = players.keys

    winner, scores_before, scores, bonuses = gen_stats
    msg_body = {:id => self.id, :winner => winner.get_details, :scores_before => scores_before, :scores => scores, :bonuses => bonuses}

    details[Constants::JSON_GAME_WINNER_ID] = winner.id

    self.details = details.to_json
    self.status = STATUS_COMPLETED
    self.save
    GameLog.log(self)
 
    message = {Constants::JSON_SOCK_MSG_TO => message_to, Constants::JSON_SOCK_MSG_TYPE => Constants::SOCK_MSG_TYPE_GAME_END, Constants::JSON_SOCK_MSG_BODY => msg_body}.to_json
    $redis.publish APP_CONFIG['sock_channel'], message
  end

  def gen_stats
    game_details = JSON.parse(self.details)
    winner_details = nil
    scores_before = {}
    scores = self.get_scores
    bonuses = game_details[Constants::JSON_GAME_BONUSES]
    winner = get_winner
    if (winner != nil)
      winner_details = winner.get_details
      winner_socket_id = winner.socket_id
      scores.each do |socket_id, score|
        player = User.where(:socket_id => socket_id).first
        if player != nil
          scores_before[socket_id] = player.score
          player.score = player.score + score
          if player.socket_id == winner_socket_id
            player.score = player.score + Constants::BONUS_WINNER[:bonus]
            bonuses[player.socket_id] << Constants::BONUS_WINNER
          end
          player.save
          scores[socket_id] = player.score
        end
      end
    end
    return winner, scores_before, scores, bonuses
  end

  def self.find_by_socket_id(socket_id, status)
    res = []
    games = Game.all
    if status != nil
      games = Game.where("status = (?) and (player1_socketid = (?) or player2_socketid = (?))",status, socket_id, socket_id)
    else
      games = Game.where("player1_socketid = (?) or player2_socketid = (?)", socket_id, socket_id)
    end
    return games
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

  def get_ready_players_count
    game_details = JSON.parse(self.details)
    players = game_details[Constants::JSON_GAME_PLAYERS]
    ready_players = 0
    players.each do |sockid, status|
      if ( players[sockid] == Game::PLAYER_STATUS_WAITING )
        ready_players = ready_players + 1
      end
    end
    game = Game.where(:id => self.id).first
    ready_players = 2 if ((game.player1_status == Game::PLAYER_STATUS_WAITING) and (game.player2_status == Game::PLAYER_STATUS_WAITING))
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

  def give_bonus(socket_id, bonus)
    game_details = JSON.parse(self.details)
    game_details[Constants::JSON_GAME_BONUSES][socket_id] << bonus
    self.details = game_details.to_json
    self.save
  end

end
