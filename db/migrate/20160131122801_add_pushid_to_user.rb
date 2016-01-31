class AddPushidToUser < ActiveRecord::Migration
  def change
    add_column :users, :pushid, :text
  end
end
