class AddAliveFlagToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :alive, :boolean
  end

  def self.down
    remove_column :pages, :alive
  end
end
