class CreateTagDescriptors < ActiveRecord::Migration
  def change
    create_table :tag_descriptors do |t|
      t.string :tag_id
      t.string :tag_name

      t.timestamps
    end
  end
end
