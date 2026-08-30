class RemoveOrderDesignParamsFromOrder < ActiveRecord::Migration[8.1]
  def change
    remove_column :orders, :x, :integer
    remove_column :orders, :y, :integer
    remove_column :orders, :wx, :integer
    remove_column :orders, :wy, :integer
    remove_column :orders, :rotation, :integer
  end
end
