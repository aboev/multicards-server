class GameLog < ActiveRecord::Base

  self.table_name = "game_log"

  def self.log(game)
    details_json = JSON.parse(game.details)
    log = GameLog.where(:game_id => game.id).first
    log = GameLog.new if log == nil
    log.game_id = game.id
    log.status = game.status
    log.gid = details_json[Constants::JSON_GAME_GID]
    players = details_json[Constants::JSON_GAME_PLAYERS]
    player1_id = -1
    player2_id = -1
    players.each do |socket_id, status|
      player = User.where(:socket_id => socket_id).first
      if (player != nil)
        if player1_id == -1
          player1_id = player.id
        else
          player2_id = player.id
        end
        break if ((player1_id != -1) and (player2_id != -1))
      end
    end
    if game.status == Game::STATUS_COMPLETED
      winner_id = details_json[Constants::JSON_GAME_WINNER_ID]
      log.winner = winner_id 
    end
    log.player1 = player1_id
    log.player2 = player2_id
    log.save
  end

end
