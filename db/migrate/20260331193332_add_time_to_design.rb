class AddTimeToDesign < ActiveRecord::Migration[8.1]
  def change
    add_column :designs, :time, :integer
  end
end
