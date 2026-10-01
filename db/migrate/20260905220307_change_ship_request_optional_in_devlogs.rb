require_relative "../migrate_helpers"

class ChangeShipRequestOptionalInDevlogs < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    change_column_null :devlogs, :ship_request_id, true if column_exists?(:devlogs, :ship_request_id)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end