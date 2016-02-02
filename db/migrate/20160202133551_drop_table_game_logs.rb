class DropTableGameLogs < ActiveRecord::Migration
  def change
    drop_table :game_logs
  end
end
