class AddDevloggedTimeToDesign < ActiveRecord::Migration[8.1]
  def change
    add_column :designs, :devlogged_time, :integer
  end
end
