class AddStatusToDesign < ActiveRecord::Migration[8.1]
  def change
    add_column :designs, :status, :integer
  end
end
