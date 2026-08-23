class AddColorToVariant < ActiveRecord::Migration[8.1]
  def change
    add_column :variants, :color_hex, :string
  end
end
