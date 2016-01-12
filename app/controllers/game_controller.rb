require 'constants'
require 'utils'

class GameController < ApplicationController
skip_before_filter :verify_authenticity_token

def new
  gid = request.headers[Constants::HEADER_SETID]
  opponent_name = request.headers[Constants::HEADER_OPPONENTNAME]
  setid = -1
  game = nil
  if (opponent_name == nil)
    game = Game.where(status: Game::STATUS_SEARCHING_PLAYERS, setid: setid).first
  elsif (opponent_name != "-1")
    opponent = User.find_by_name(opponent_name)
    if opponent != nil
      game = Game.find_by_socket_id(opponent.socket_id, Game::STATUS_WAITING_OPPONENT).first
    end
  end
  if gid != nil
    cardset = Utils.get_cardset(gid)
    if cardset != nil
      game = Game.where(status: Game::STATUS_SEARCHING_PLAYERS, setid: cardset.id).first
      setid = cardset.id
    end
  end
  if (game != nil)
    game.join_player(@user)
    game.start_game
  else
    game = Game.new
    game.init(setid, (opponent_name == "-1") ? false : true)
    game.join_player(@user)
  end
  game_details = JSON.parse(game.details)
  msg = { :result => Constants::RESULT_OK, :data => game_details }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
