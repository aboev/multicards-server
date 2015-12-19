class ChangeDataTypeForCardsetDetails < ActiveRecord::Migration
  def change
    change_column :cardsets, :details, :text, :limit => nil
  end
end
