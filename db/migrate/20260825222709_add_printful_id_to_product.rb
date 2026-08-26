class AddPrintfulIdToProduct < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :printful_id, :integer
  end
end
