class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :url
      t.boolean :spam
      t.string :title
      t.string :original_url
      t.string :description
      t.string :image_url
      t.timestamps
    end
    add_index :pages, :url
  end

  def self.down
    drop_table :pages
  end
end
