class AddColorToOrder < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :color_hex, :string
  end
end
