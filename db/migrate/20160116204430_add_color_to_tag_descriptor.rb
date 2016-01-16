class AddColorToTagDescriptor < ActiveRecord::Migration
  def change
    add_column :tag_descriptors, :color, :string
  end
end
