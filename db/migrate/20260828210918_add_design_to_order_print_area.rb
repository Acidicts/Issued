require_relative "../migrate_helpers"

class AddDesignToOrderPrintArea < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :order_print_areas do
      # orders.design_id still exists at this point in the migration history and
      # is the design each print area was generated from.
      add_reference_backfilled :order_print_areas, :design, foreign_key: true,
        backfill_sql: "SELECT o.design_id FROM orders AS o WHERE o.id = t.order_id"
    end
  end

  def down
    if_table_exists :order_print_areas do
      remove_reference :order_print_areas, :design, foreign_key: true
    end
  end
end
