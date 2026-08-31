class AddNameToOrderPrintArea < ActiveRecord::Migration[8.1]
  def change
    add_column :order_print_areas, :name, :string, default: ""
  end
end
