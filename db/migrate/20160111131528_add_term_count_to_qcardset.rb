class AddTermCountToQcardset < ActiveRecord::Migration
  def change
    add_column :qcardsets, :term_count, :integer
  end
end
