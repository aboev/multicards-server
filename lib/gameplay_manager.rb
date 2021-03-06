require 'question'
require 'constants'
require 'game'
require 'game_log'
require 'push'

class GameplayManager

  def self.init_and_join(gid, rnd_opp, user, status)
    games = Game.find_by_player_id(user.id, nil)
    games.each do |game|
      game.stop_game if game.status == Game::STATUS_IN_PROGRESS
      game.destroy
    end

    game = Game.new
    game.init(gid, rnd_opp)
    game.join_player(user, status)
    GameLog.log(game)
    return game
  end

  def self.join_and_start(game, user, gid)
    game.join_player(user, nil)
    game.start_game
    GameLog.log(game)
  end

  def self.start_game(game)
    game_details = JSON.parse(game.gameplay_data)
    cardset = Qcardset.where(:cardset_id => game.setid).first
    if ((cardset != nil) and (!cardset.flags.include?(Constants::FLAG_DISCOVERED.to_s)))
      cardset.add_flag(Constants::FLAG_DISCOVERED)
      cardset.save
      if ((game.player1_socketid != nil) and (game.player1_socketid.length > 0))
        game.give_bonus(game.player1_socketid, Constants::BONUS_DISCOVERER)
      end
    end
  end

  def self.invite_user(id_from, opponent_name, game_id)
    user_from = User.where(:socket_id => id_from).first
    user_to = User.find_by_name(opponent_name)
    id_to = user_to.socket_id if user_to != nil
    game = Game.where(:id => game_id.to_i).first
    cardset = Qcardset.where(:cardset_id => game.setid).first
    return if ((game == nil) or (user_from == nil) or (cardset == nil) or (id_to == nil))
    msg_to = [id_to]
    msg_type = Constants::SOCK_MSG_TYPE_GAME_INVITE
    msg_body = Protocol.make_invitation(user_from, game, cardset)
    message = Protocol.make_msg(msg_to, msg_type, msg_body)
    if ((user_to.pushid != nil) and (user_to.pushid.length > 0))
      PushSender.perform(user_to.id, msg_type, msg_body)
    else
      $redis.publish APP_CONFIG['sock_channel'], message
    end
  end

  def self.accept_invitation(id_from, game_id, invitation_json)
    game = Game.where(:id => game_id.to_i).first
    user_from = User.where(:socket_id => id_from).first
    if (user_from == nil)
      return
    elsif (game == nil)
      return if invitation_json == nil
      invitation = JSON.parse(invitation_json)
      game = invitation[Constants::JSON_INVITATION_GAME]
      user_details = invitation[Constants::JSON_INVITATION_USER]  
      game_gid = game[Constants::JSON_GAME_GID]
      user_name = user_details[Constants::JSON_USER_NAME]
      game = GameplayManager.init_and_join(game_gid, false, user_from, Game::PLAYER_STATUS_PENDING)
      invite_user(id_from, user_name, game.id)
    else
      game.join_player(user_from, Game::PLAYER_STATUS_PENDING)
      msg_to = [game.player1_socketid]
      msg_type = Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED
      msg_body = game_id
      message = Protocol.make_msg(msg_to, msg_type, msg_body)
      $redis.publish APP_CONFIG['sock_channel'], message
    end
  end

  def self.reject_invitation(id_from, game_id)
    game = Game.where(:id => game_id.to_i).first
    user_from = User.where(:socket_id => id_from).first
    return if ((game == nil) or (user_from == nil))
    msg_to = [game.player1_socketid]
    msg_type = Constants::SOCK_MSG_TYPE_INVITE_REJECTED
    msg_body = game_id
    message = Protocol.make_msg(msg_to, msg_type, msg_body)
    $redis.publish APP_CONFIG['sock_channel'], message
    game.destroy
  end

  def self.status_update(user_from, status)
    game = Game.find_by_socket_id(user_from, nil).first
    return if game == nil
    game_details = JSON.parse(game.details)
    gameplay_data = JSON.parse(game.gameplay_data)

    game.set_player_status(user_from, status)
    players_ready = game.get_players_count() == game.get_ready_players_count()

    if ((game.status == Game::STATUS_SEARCHING_PLAYERS) or (game.status == Game::STATUS_WAITING_OPPONENT))
      msg_to = [game.player2_socketid]
      msg_to = [game.player1_socketid] if game.player2_socketid == user_from
      msg_type = Constants::SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE
      msg_body = status
      message = Protocol.make_msg(msg_to, msg_type, msg_body)
      $redis.publish APP_CONFIG['sock_channel'], message  
      game.start_game if players_ready
    elsif ((game.status == Game::STATUS_IN_PROGRESS) and players_ready)
      questions_count = game_details[Constants::JSON_GAME_QUESTIONCNT]
      if ((questions_count >= Constants::GAMEPLAY_Q_PER_G) or (questions_count == (gameplay_data['questions'].length)))
        game.end_game
        game.destroy
      else
        game.next_question
      end
    end

  end

  def self.change_gid(socketid, game_id, gid)
    game = Game.find_by_socket_id(socketid, nil).first
    return if ((game == nil) or (game.status == Game::STATUS_IN_PROGRESS))
    setid = Utils.parse_gid(gid)[1]
    gameplay_data = GameplayData.new(setid)
    game_details = JSON.parse(game.details)
    game_details[Constants::JSON_GAME_GID] = gid
    game.setid = setid
    game.details = game_details.to_json
    game.gameplay_data = gameplay_data.to_json.to_json 
    game.save

    id_to = game_details[Constants::JSON_GAME_PLAYERS].keys
    msg_to = [id_to]
    msg_type = Constants::SOCK_MSG_TYPE_SET_GID
    msg_body = gid
    msg_extra = game_id
    message = Protocol.make_msg_extra(msg_to, msg_type, msg_body, msg_extra)
    $redis.publish APP_CONFIG['sock_channel'], message
  end

  def self.update_socketid(old_socketid, new_socketid)

  end

end
