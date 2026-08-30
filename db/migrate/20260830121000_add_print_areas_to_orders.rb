class AddPrintAreasToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :print_areas, :jsonb, default: {}, null: false
  end
end
