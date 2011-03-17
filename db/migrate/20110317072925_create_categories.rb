class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.string :name
      t.string :query
      t.integer :parent_cid, :default => 0
      t.timestamps
    end
    add_index :categories, :name
  end

  def self.down
    drop_table :categories
  end
end
