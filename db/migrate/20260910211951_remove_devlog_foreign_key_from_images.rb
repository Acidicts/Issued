require_relative "../migrate_helpers"

class RemoveDevlogForeignKeyFromImages < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    remove_foreign_key :images, :devlogs, if_exists: true
  end

  def down
    add_foreign_key :images, :devlogs, if_not_exists: true
  end
end
