class ChangeCostInPrintAreaToFloat < ActiveRecord::Migration[8.1]
  def change
    change_column :print_areas, :cost, :float
  end
end
