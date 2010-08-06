class AddUrlCustomFieldType < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :pattern, :string, :default => ""
  end

  def self.down
    remove_column :custom_fields, :pattern
  end
end
