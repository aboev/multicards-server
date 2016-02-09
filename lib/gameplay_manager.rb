require 'question'
require 'constants'
require 'game'

class GameplayManager

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

  def self.invite_user(id_from, id_to, game_id)
    user_from = User.where(:id => id_from).first
    game = Game.where(:id => game_id).first
    return if ((game == nil) or (user_from == nil))
    msg_to = [id_to]
    msg_type = Constants::SOCK_MSG_TYPE_GAME_INVITE
    msg_body = JSON.parse(game.details)
    msg_extra = JSON.parse(user_from.details)
    message = Protocol.make_msg_extra(msg_to, msg_type, msg_body, msg_extra)
    $redis.publish Constants::SOCK_CHANNEL, message
  end

  def self.invitation_accepted(user_from, game_id)
    game = Game.where(:id => game_id).first
    return if game == nil
    msg_to = game.player1_socketid
    msg_type = Constants::SOCK_MSG_TYPE_INVITE_ACCEPTED
    msg_body = game_id
    message = Protocol.make_msg(msg_to, msg_type, msg_body)
    $redis.publish Constants::SOCK_CHANNEL, message
  end

  def self.status_update(user_from, status)
    game = Game.find_by_socket_id(user_from, nil).first
    return if game == nil
    game_details = JSON.parse(game.details)
    gameplay_data = JSON.parse(game.gameplay_data)

    game.set_player_status(user_from, status)
    players_ready = game.get_players_count() == game.get_ready_players_count()

    if ((game.status == Game::STATUS_SEARCHING_PLAYERS) or (game.status == Game::STATUS_WAITING_OPPONENT))
      msg_to = game_details[Constants::JSON_GAME_PLAYERS].keys
      msg_to.delete(user_from)
      msg_type = Constants::SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE
      msg_body = status
      message = Protocol.make_msg(msg_to, msg_type, msg_body)
      $redis.publish Constants::SOCK_CHANNEL, message  
      game.start_game if players_ready
    elsif game.status == Game::STATUS_IN_PROGRESS
      questions_count = game_details[Constants::JSON_GAME_QUESTIONCNT]
      if ((questions_count >= Constants::GAMEPLAY_Q_PER_G) or (questions_count == (gameplay_data['questions'].length)))
        game.end_game
        game.destroy
      else
        game.next_question
      end
    end

  end

end
