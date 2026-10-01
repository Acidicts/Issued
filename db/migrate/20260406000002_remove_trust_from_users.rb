require_relative "../migrate_helpers"

class RemoveTrustFromUsers < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    remove_column :users, :trust, :integer, if_exists: true
  end

  def down
    add_column :users, :trust, :integer, default: 0, null: false, if_not_exists: true
  end
end