class AddFlagsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :flags, :string, default: [], array: true
  end
end
