class AddPlayer1SocketidToGame < ActiveRecord::Migration
  def change
    add_column :games, :player1_socketid, :string
  end
end
