class AddStockByRegionToVariants < ActiveRecord::Migration[7.0]
  def change
    add_column :variants, :stock_by_region, :jsonb, default: {}, null: false
    add_index :variants, :stock_by_region, using: :gin, if_not_exists: true
  end
end
