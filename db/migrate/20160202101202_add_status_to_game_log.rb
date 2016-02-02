class AddStatusToGameLog < ActiveRecord::Migration
  def change
    add_column :game_log, :status, :integer
  end
end
