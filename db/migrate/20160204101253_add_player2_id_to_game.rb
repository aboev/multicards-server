class AddPlayer2IdToGame < ActiveRecord::Migration
  def change
    add_column :games, :player2_id, :integer
  end
end
