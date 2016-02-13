class AddPlayer2StatusToGame < ActiveRecord::Migration
  def change
    add_column :games, :player2_status, :string
  end
end
