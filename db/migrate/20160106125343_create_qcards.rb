class CreateQcards < ActiveRecord::Migration
  def change
    create_table :qcards do |t|
      t.integer :cardset_id, limit: 8
      t.integer :term_id, limit: 8
      t.text :term
      t.text :definition
      t.text :image
      t.integer :rank

      t.timestamps
    end
  end
end
