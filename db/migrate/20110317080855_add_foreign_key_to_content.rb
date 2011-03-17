class AddForeignKeyToContent < ActiveRecord::Migration
  def self.up
    add_column :contents, :category_id, :integer
    add_index :contents, :category_id
  end

  def self.down
    remove_column :contents, :category_id, :integer
  end
end
