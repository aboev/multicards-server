class ChangeDataTypeForCarsetDetails < ActiveRecord::Migration
  def change
    change_column :cardsets, :details,  :text
  end
end
