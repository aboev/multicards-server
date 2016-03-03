class AddDeviceidToUser < ActiveRecord::Migration
  def change
    add_column :users, :deviceid, :text
  end
end
