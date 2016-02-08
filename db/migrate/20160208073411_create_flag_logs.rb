class CreateFlagLogs < ActiveRecord::Migration
  def change
    create_table :flag_log do |t|
      t.integer :user_id
      t.string :gid
      t.string :flag_id

      t.timestamps
    end
  end
end
