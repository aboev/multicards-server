class GameLog < ActiveRecord::Base

  self.table_name = "game_log"

  def self.log(game, gid)
    details_json = JSON.parse(game.details)
    log = GameLog.new
    log.game_id = game.id
    log.gid = gid
    log.status = details_json[Constants::JSON_GAME_STATUS]
    players = details_json[Constants::JSON_GAME_PLAYERS]
    player1_id = -1
    player2_id = -1
    players.each do |socket_id, status|
      player = User.where(:socket_id => socket_id).first
      if (player != nil)
        player1_id = player.id if player1_id == -1
        player2_id = player.id if player1_id != -1
        break if ((player1_id != -1) and (player2_id != -1))
      end
    end
    log.player1 = player1_id
    log.player2 = player2_id
    log.save
  end

end
