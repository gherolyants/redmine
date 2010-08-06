class AddUseUserCredentialsToRequestLdap < ActiveRecord::Migration
  def self.up
    add_column :auth_sources, :use_user_credentials, :boolean, :default => false
  end

  def self.down
    remove_column :auth_sources, :use_user_credentials
  end
end
