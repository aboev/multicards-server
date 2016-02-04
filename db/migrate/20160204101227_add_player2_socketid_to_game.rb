class AddPlayer2SocketidToGame < ActiveRecord::Migration
  def change
    add_column :games, :player2_socketid, :string
  end
end
