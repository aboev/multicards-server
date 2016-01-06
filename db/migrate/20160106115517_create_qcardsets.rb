class CreateQcardsets < ActiveRecord::Migration
  def change
    create_table :qcardsets do |t|
      t.integer :cardset_id, :limit => 5
      t.text :url
      t.text :title
      t.integer :created_date
      t.integer :modified_date
      t.integer :published_date
      t.boolean :has_images
      t.string :lang_terms, :limit => 7
      t.string :lang_definitions, :limit => 7
      t.integer :creator_id, :limit => 5
      t.text :description
      t.string :likes, default: [], array: true
      t.integer :like_count, default: 0
      t.integer :total_diff, default: 0
      t.integer :diff_count, default: 0

      t.timestamps
    end
  end
end
