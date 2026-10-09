require_relative "../migrate_helpers"

class AddUniqueIndexToDesignsUserIdName < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  # Duplicates predate the index (designs defaulted to "Untitled Design"), so
  # rename the later rows instead of dropping data, then add the index.
  def up
    if_table_exists :designs do
      dedupe_design_names!
      add_index :designs, [ :user_id, :name ], unique: true, if_not_exists: true
    end
  end

  def down
    if_table_exists :designs do
      remove_index :designs, [ :user_id, :name ], if_exists: true
    end
  end

  private

  def dedupe_design_names!
    execute <<~SQL
      UPDATE designs AS d
      SET name = d.name || ' (' || dupes.rn || ')'
      FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                 PARTITION BY user_id, name
                 ORDER BY created_at ASC, id ASC
               ) AS rn
        FROM designs
      ) AS dupes
      WHERE d.id = dupes.id AND dupes.rn > 1
    SQL
  end
end
