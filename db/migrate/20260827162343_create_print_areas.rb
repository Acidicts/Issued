class CreatePrintAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :print_areas do |t|
      t.integer :image_x
      t.integer :image_y
      t.integer :image_wx
      t.integer :image_wy
      t.references :product, null: false, foreign_key: true
      t.integer :cost
      t.integer :thread_cost
      t.string :name
      t.boolean :enabled, default: false

      t.timestamps
    end
  end
end
