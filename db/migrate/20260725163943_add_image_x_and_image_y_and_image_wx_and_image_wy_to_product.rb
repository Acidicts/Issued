class AddImageXAndImageYAndImageWxAndImageWyToProduct < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :image_x, :integer, default: 0, null: false
    add_column :products, :image_y, :integer, default: 0, null: false
    add_column :products, :image_wx, :integer, default: 0, null: false
    add_column :products, :image_wy, :integer, default: 0, null: false
  end
end
