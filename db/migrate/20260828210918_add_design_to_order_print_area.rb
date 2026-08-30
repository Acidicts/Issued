class AddDesignToOrderPrintArea < ActiveRecord::Migration[8.1]
  def change
    add_reference :order_print_areas, :design, null: false, foreign_key: true
  end
end
