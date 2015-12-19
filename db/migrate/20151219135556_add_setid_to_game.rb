class AddSetidToGame < ActiveRecord::Migration
  def change
    add_column :games, :setid, :integer
  end
end
