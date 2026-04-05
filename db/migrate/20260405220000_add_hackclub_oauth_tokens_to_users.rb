class AddHackclubOauthTokensToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :hackclub_access_token, :text
    add_column :users, :hackclub_refresh_token, :text
  end
end
