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

end
