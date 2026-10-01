require_relative "../migrate_helpers"

class RemoveHackatimeProjectFromDesign < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :designs do
      remove_column :designs, :hackatime_project, :string, if_exists: true
    end
  end

  def down
    if_table_exists :designs do
      add_column :designs, :hackatime_project, :string, if_not_exists: true
    end
  end
end