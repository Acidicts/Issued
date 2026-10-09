require_relative "../migrate_helpers"

class RemoveDesignFromOrder < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :orders do
      remove_reference :orders, :design, if_exists: true
    end
  end

  def down
    if_table_exists :orders do
      add_reference_backfilled :orders, :design, foreign_key: true,
        backfill_sql: "SELECT opa.design_id FROM order_print_areas AS opa WHERE opa.order_id = t.id LIMIT 1"
    end
  end
end
