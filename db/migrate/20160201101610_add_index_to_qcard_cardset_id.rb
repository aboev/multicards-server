class AddIndexToQcardCardsetId < ActiveRecord::Migration
  def change
    add_index :qcards, :cardset_id
  end
end
