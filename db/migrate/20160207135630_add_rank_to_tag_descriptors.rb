class AddRankToTagDescriptors < ActiveRecord::Migration
  def change
    add_column :tag_descriptors, :rank, :integer
  end
end
