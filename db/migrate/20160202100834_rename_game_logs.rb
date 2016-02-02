class RenameGameLogs < ActiveRecord::Migration
  def self.up
    rename_table :game_logs, :game_log
  end

 def self.down
    rename_table :game_log, :game_logs
 end
end
