require 'constants'
require 'utils'
require 'gameplay_manager'

class GameController < ApplicationController
skip_before_filter :verify_authenticity_token

def start
  gid = request.headers[Constants::HEADER_SETID]
  opponent_name = request.headers[Constants::HEADER_OPPONENTNAME]
  multiplayer_type = request.headers[Constants::HEADER_MULTIPLAYER_TYPE]

  if (multiplayer_type == nil)
    ret_error(Constants::ERROR_MISSING_HEADER, Constants::MSG_MISSING_HEADER)
    return
  end

  if (multiplayer_type == Constants::MULTIPLAYER_TYPE_NEW)
    if ((gid == nil) or (Utils.get_qcardset(gid) == nil))
      ret_error(Constants::ERROR_CARDSET_NOT_FOUND, Constants::MSG_CARDSET_NOT_FOUND)
      return
    end
    rnd_opp = ((opponent_name == nil) or (opponent_name.length == 0))
    if ((rnd_opp == false) and (opponent = User.find_by_name(opponent_name)) == nil)
      ret_error(Constants::ERROR_USER_NOT_FOUND, Constants::MSG_USER_NOT_FOUND)
      return
    end
    game = GameplayManager.init_and_join(gid, rnd_opp, @user, Game::PLAYER_STATUS_PENDING)
    game.join_player(opponent, Game::PLAYER_STATUS_PENDING) if opponent != nil
    GameplayManager.invite_user(@user.socket_id, opponent_name, game.id) if opponent_name != nil
    ret_ok(JSON.parse(game.details))
    return
  elsif (multiplayer_type == Constants::MULTIPLAYER_TYPE_JOIN)
    if ((opponent_name == nil) or ((opponent = User.find_by_name(opponent_name)) == nil))
      ret_error(Constants::ERROR_USER_NOT_FOUND, Constants::MSG_USER_NOT_FOUND)
      return
    end
    game = Game.where(:player1_id => opponent.id).first
    if ((game == nil) or (game.status == Game::STATUS_IN_PROGRESS))
      ret_error(Constants::ERROR_GAME_NOT_FOUND, Constants::MSG_GAME_NOT_FOUND)
      return
    end
    game.join_player(@user, Game::PLAYER_STATUS_PENDING)
    ret_ok(JSON.parse(game.details))
  end

end

def new
  gid = request.headers[Constants::HEADER_SETID]
  opponent_name = request.headers[Constants::HEADER_OPPONENTNAME]
  multiplayer_type = request.headers[Constants::HEADER_MULTIPLAYER_TYPE]

  if ((gid == nil) and ((opponent_name == "-1") or (opponent_name == nil)))
    ret_error()
    return
  elsif ((gid != nil) and (gid.length > 0) and (Utils.get_qcardset(gid) == nil))
    ret_error()
    return
  end

  setid = Utils.parse_gid(gid)[1]
  if (opponent_name == nil)
    game_public = Game.where(status: Game::STATUS_SEARCHING_PLAYERS, setid: setid).first
    if game_public != nil
      GameplayManager.join_and_start(game_public, @user, gid)
      ret_ok(JSON.parse(game_public.details))
      return
    else
      game_public = GameplayManager.init_and_join(gid, true, @user, nil)
      ret_ok(JSON.parse(game_public.details))
      return
    end
  elsif (opponent_name == "-1")
    game_private = GameplayManager.init_and_join(gid, false, @user, nil)
    ret_ok(JSON.parse(game_private.details))
    return
  else
    opponent = User.find_by_name(opponent_name)
    if opponent != nil
      game_private = Game.find_by_socket_id(opponent.socket_id, Game::STATUS_WAITING_OPPONENT).first
      GameplayManager.join_and_start(game_private, @user, gid)
      ret_ok(JSON.parse(game_private.details))
      return
    else
      ret_error(Constants::ERROR_USER_NOT_FOUND, Constants::MSG_USER_NOT_FOUND)
      return
    end
  end
end

def get
  res = []
  games_public = Game.where(status: Game::STATUS_SEARCHING_PLAYERS)
  games_public.each do |game|
    cardset = Qcardset.where(:cardset_id => game.setid).first
    res_item = JSON.parse(game.details)
    res_item[:cardset] = cardset
    res << res_item
  end
  ret_ok(res)
end

def invitations
  games = Game.where(status: Game::STATUS_WAITING_OPPONENT, player2_id: @user.id)
  res = []
  games.each do |game|
    cardset = Qcardset.where(:cardset_id => game.setid).first
    user_from = User.where(:id => game.player1_id).first
    res << Protocol.make_invitation(user_from, game, cardset) if ((user_from != nil) and (cardset != nil))
  end
  ret_ok(res)
end

def ret_ok (data)
  msg = { :result => Constants::RESULT_OK, :data => data }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def ret_error
  msg = { :result => Constants::RESULT_ERROR }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def ret_error(err_code, err_msg)
  msg = { :result => Constants::RESULT_ERROR, :code => err_code, :msg => err_msg }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
