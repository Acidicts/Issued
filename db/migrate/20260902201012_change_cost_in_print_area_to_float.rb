require_relative "../migrate_helpers"

class ChangeCostInPrintAreaToFloat < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    change_column :print_areas, :cost, :float if column_exists?(:print_areas, :cost)
  end

  def down
    change_column :print_areas, :cost, :integer if column_exists?(:print_areas, :cost)
  end
end