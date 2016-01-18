class ChangeDataTypeForId < ActiveRecord::Migration

  def self.up
    change_table :qcards do |t|
      t.change :id, :integer, limit: 8
    end
  end

  def self.down
    change_table :qcards do |t|
      t.change :id, :integer
    end
  end
end
