class AddEnabledToProduct < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :enabled, :boolean
  end
end
