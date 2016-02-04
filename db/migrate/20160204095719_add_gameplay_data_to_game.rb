class AddGameplayDataToGame < ActiveRecord::Migration
  def change
    add_column :games, :gameplay_data, :text
  end
end
