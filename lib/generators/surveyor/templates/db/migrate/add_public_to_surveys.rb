# encoding: UTF-8
class AddPublicToSurveys < ActiveRecord::Migration[5.2]
  def self.up
    add_column :surveys, :public, :boolean
  end

  def self.down
    remove_column :surveys, :public
  end
end
