class AddNameToDesigns < ActiveRecord::Migration[8.1]
  def change
    add_column :designs, :name, :string, null: false, default: "Untitled Design"
    add_index :designs, :name
  end
end
