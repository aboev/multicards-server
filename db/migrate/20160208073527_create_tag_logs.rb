class CreateTagLogs < ActiveRecord::Migration
  def change
    create_table :tag_log do |t|
      t.integer :user_id
      t.string :gid
      t.string :tag_id

      t.timestamps
    end
  end
end
