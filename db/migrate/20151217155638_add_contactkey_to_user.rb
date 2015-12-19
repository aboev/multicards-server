class AddContactkeyToUser < ActiveRecord::Migration
  def change
    add_column :users, :contactkey, :string
  end
end
