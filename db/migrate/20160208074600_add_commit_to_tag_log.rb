class AddCommitToTagLog < ActiveRecord::Migration
  def change
    add_column :tag_log, :commit, :boolean
  end
end
