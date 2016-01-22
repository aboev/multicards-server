require 'constants'
require 'utils'

class GameController < ApplicationController
skip_before_filter :verify_authenticity_token

def new
  gid = request.headers[Constants::HEADER_SETID]
  opponent_name = request.headers[Constants::HEADER_OPPONENTNAME]

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
      join_and_start(game_public, @user)
      ret_ok(JSON.parse(game_public.details))
      return
    else
      game_public = init_and_join(setid, true, @user)
      ret_ok(JSON.parse(game_public.details))
      return
    end
  elsif (opponent_name == "-1")
    game_private = init_and_join(setid, false, @user)
    ret_ok(JSON.parse(game_private.details))
    return
  else
    opponent = User.find_by_name(opponent_name)
    if opponent != nil
      game_private = Game.find_by_socket_id(opponent.socket_id, Game::STATUS_WAITING_OPPONENT).first
      join_and_start(game_private, @user)
      ret_ok(JSON.parse(game_private.details))
      return
    else
      ret_error(Constants::ERROR_USER_NOT_FOUND, Constants::MSG_USER_NOT_FOUND)
      return
    end
  end
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

def join_and_start(game, user)
  game.join_player(user)
  game.start_game
end

def init_and_join(setid, rnd_opp, user)
  game = Game.new
  game.init(setid, rnd_opp)
  game.join_player(user)
  return game
end

end
