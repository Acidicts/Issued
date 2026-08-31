class AddDesignImageNumToOrderPrintArea < ActiveRecord::Migration[8.1]
  def change
    add_column :order_print_areas, :design_image_num, :integer, default: 0
  end
end
