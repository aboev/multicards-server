class AddFlagsToQcardsets < ActiveRecord::Migration
  def change
    add_column :qcardsets, :flags, :string, default: [], array: true
  end
end
