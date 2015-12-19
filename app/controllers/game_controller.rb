require 'constants'
require 'utils'

class GameController < ApplicationController
skip_before_filter :verify_authenticity_token

def new
  gid = request.headers[Constants::HEADER_SETID]
  setid = -1
  game = Game.where(status: Game::STATUS_SEARCHING_PLAYERS, setid: setid).first
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
    game.init(setid)
    game.join_player(@user)
  end
  game_details = JSON.parse(game.details)
  msg = { :result => Constants::RESULT_OK, :data => game_details }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
