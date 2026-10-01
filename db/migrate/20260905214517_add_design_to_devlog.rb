require_relative "../migrate_helpers"

class AddDesignToDevlog < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :devlogs do
      # A devlog's design is reachable through the ship request it belongs to.
      add_reference_backfilled :devlogs, :design, foreign_key: true,
        backfill_sql: "SELECT sr.design_id FROM ship_requests AS sr WHERE sr.id = t.ship_request_id"
    end
  end

  def down
    if_table_exists :devlogs do
      remove_reference :devlogs, :design, foreign_key: true
    end
  end
end