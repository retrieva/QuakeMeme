class AlterImageUrlFromVarcharToText < ActiveRecord::Migration
  def self.up
    change_column :pages, :image_url, :text
  end

  def self.down
    change_column :pages, :image_url, :string
  end
end
