require_relative "../migrate_helpers"

class AddHackatimeFieldsToDesigns < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :designs do
      add_column :designs, :hackatime_project, :string, if_not_exists: true
      add_column :designs, :hackatime_seconds, :integer, if_not_exists: true

      # The unique index only survives until RemoveHackatimeProjectFromDesign, so
      # skip it if any designs already share a project rather than failing the
      # whole migration.
      duplicates = select_value(<<~SQL.squish).to_i.positive?
        SELECT COUNT(*) FROM (
          SELECT hackatime_project FROM designs
          WHERE hackatime_project IS NOT NULL
          GROUP BY hackatime_project HAVING COUNT(*) > 1
        ) AS dupes
      SQL

      add_index :designs, :hackatime_project, unique: true, if_not_exists: true unless duplicates
    end
  end

  def down
    if_table_exists :designs do
      remove_index :designs, :hackatime_project, if_exists: true
      remove_column :designs, :hackatime_seconds, :integer, if_exists: true
      remove_column :designs, :hackatime_project, :string, if_exists: true
    end
  end
end
