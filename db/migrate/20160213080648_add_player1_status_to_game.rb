class AddPlayer1StatusToGame < ActiveRecord::Migration
  def change
    add_column :games, :player1_status, :string
  end
end
