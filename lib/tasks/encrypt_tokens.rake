namespace :encryption do
  desc "Migrate existing plaintext OAuth tokens to encrypted columns"
  task migrate_tokens: :environment do
    User.find_each do |user|
      # Read raw values directly from DB to bypass encryption layer
      row = User.connection.select_one(
        "SELECT hackclub_access_token, hackclub_refresh_token FROM users WHERE id = #{user.id}"
      )

      access_token = row["hackclub_access_token"]
      refresh_token = row["hackclub_refresh_token"]

      next if access_token.blank? && refresh_token.blank?

      # Rails 7.1+ encrypts on read if column has `encrypts` declaration.
      # If the value starts with a known encryption prefix it's already encrypted.
      next if access_token.present? && access_token.start_with?("pql0")

      # Clear first, then write through model to trigger encryption
      User.connection.execute(
        "UPDATE users SET hackclub_access_token = NULL, hackclub_refresh_token = NULL WHERE id = #{user.id}"
      )
      user.reload
      user.update!(
        hackclub_access_token: access_token.presence,
        hackclub_refresh_token: refresh_token.presence
      )
      puts "Migrated tokens for User##{user.id}"
    rescue => e
      puts "Error on User##{user.id}: #{e.message}"
    end

    puts "Done."
  end
end
