class AddImageParamsToOrder < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :x, :integer
    add_column :orders, :y, :integer
    add_column :orders, :wx, :integer
    add_column :orders, :wy, :integer
  end
end
