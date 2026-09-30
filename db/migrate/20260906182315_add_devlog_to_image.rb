class AddDevlogToImage < ActiveRecord::Migration[8.1]
  def up
    return if column_exists?(:images, :devlog_id)

    add_reference :images, :devlog, null: true, foreign_key: true

    # Existing images predate devlogs, so backfill each row with a devlog on the
    # same design before tightening the constraint.
    execute <<~SQL
      UPDATE images
      SET devlog_id = (
        SELECT devlogs.id FROM devlogs
        WHERE devlogs.design_id = images.design_id
        ORDER BY devlogs.created_at ASC, devlogs.id ASC
        LIMIT 1
      )
      WHERE devlog_id IS NULL
    SQL

    if select_value("SELECT COUNT(*) FROM images WHERE devlog_id IS NULL").to_i.zero?
      change_column_null :images, :devlog_id, false
    end
  end

  def down
    return unless column_exists?(:images, :devlog_id)

    remove_reference :images, :devlog, foreign_key: true
  end
end
