require_relative "../migrate_helpers"

class MakeDevlogIdNullableOnImages < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    change_column_null :images, :devlog_id, true if column_exists?(:images, :devlog_id)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
