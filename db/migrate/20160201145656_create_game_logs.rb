class CreateGameLogs < ActiveRecord::Migration
  def change
    create_table :game_logs do |t|
      t.integer :game_id
      t.integer :player1
      t.integer :player2
      t.string :gid
      t.integer :winner
      t.string :result
      t.string :details

      t.timestamps
    end
  end
end
