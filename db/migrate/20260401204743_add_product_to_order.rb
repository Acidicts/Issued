require_relative "../migrate_helpers"

class AddProductToOrder < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :orders do
      # No way to infer which product an existing order belongs to, so the
      # column stays nullable when there are orders to backfill.
      add_reference_backfilled :orders, :product, foreign_key: true
    end
  end

  def down
    if_table_exists :orders do
      remove_reference :orders, :product, foreign_key: true
    end
  end
end
