class AddTagsToQcardset < ActiveRecord::Migration
  def change
    add_column :qcardsets, :tags, :string, default: [], array: true
  end
end
