class CreateOrderPrintAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :order_print_areas do |t|
      t.integer :rotation
      t.integer :x
      t.integer :y
      t.integer :xw
      t.integer :yw
      t.references :order, null: false, foreign_key: true

      t.timestamps
    end
  end
end
