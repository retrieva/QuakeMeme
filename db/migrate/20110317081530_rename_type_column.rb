class RenameTypeColumn < ActiveRecord::Migration
  def self.up
    rename_column :contents, :type, :content_type
  end

  def self.down
    rename_column :contents, :content_type, :type
  end
end
