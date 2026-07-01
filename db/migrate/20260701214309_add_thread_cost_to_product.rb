class AddThreadCostToProduct < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :thread_cost, :integer, default: 0
  end
end
