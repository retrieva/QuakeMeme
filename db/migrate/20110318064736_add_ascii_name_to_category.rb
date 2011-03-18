class AddAsciiNameToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :ascii_name, :string
  end

  def self.down
    remove_column :categories, :ascii_name
  end
end
