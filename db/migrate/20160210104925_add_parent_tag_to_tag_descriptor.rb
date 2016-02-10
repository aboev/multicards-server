class AddParentTagToTagDescriptor < ActiveRecord::Migration
  def change
    add_column :tag_descriptors, :parent_tag, :string
  end
end
