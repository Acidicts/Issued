require_relative "../migrate_helpers"

class AddUserToNotification < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :notifications do
      # Notifications have no other relation to recover a user from, so the
      # column stays nullable when there are existing rows.
      add_reference_backfilled :notifications, :user, foreign_key: true
    end
  end

  def down
    if_table_exists :notifications do
      remove_reference :notifications, :user, foreign_key: true
    end
  end
end
