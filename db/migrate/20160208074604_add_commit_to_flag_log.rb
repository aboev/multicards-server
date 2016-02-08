class AddCommitToFlagLog < ActiveRecord::Migration
  def change
    add_column :flag_log, :commit, :boolean
  end
end
