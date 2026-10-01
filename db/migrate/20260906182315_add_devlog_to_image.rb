require_relative "../migrate_helpers"

class AddDevlogToImage < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :images do
      # Images predate devlogs; attach each one to the oldest devlog on its design.
      add_reference_backfilled :images, :devlog, foreign_key: true,
        backfill_sql: <<~SQL.squish
          SELECT d.id FROM devlogs AS d
          WHERE d.design_id = t.design_id
          ORDER BY d.created_at ASC, d.id ASC
          LIMIT 1
        SQL
    end
  end

  def down
    if_table_exists :images do
      remove_reference :images, :devlog, foreign_key: true
    end
  end
end