class AddDescriptionToDesign < ActiveRecord::Migration[8.1]
  def change
    add_column :designs, :description, :string, default: ""
  end
end
