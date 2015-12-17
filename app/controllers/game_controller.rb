require 'constants'

class GameController < ApplicationController
skip_before_filter :verify_authenticity_token

def new
  game = Game.where(status: Game::STATUS_SEARCHING_PLAYERS).first
  if (game != nil)
    game.join_player(@user)
    game.start_game
  else
    game = Game.new
    game.init
    game.join_player(@user)
  end
  game_details = JSON.parse(game.details)
  msg = { :result => Constants::RESULT_OK, :data => game_details }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
