class RemoveRegionAndAddProductToVariant < ActiveRecord::Migration[8.1]
  def change
    add_reference :variants, :product, null: false, foreign_key: true
    remove_reference :variants, :region, null: false, foreign_key: true
    drop_table :regions
  end
end
