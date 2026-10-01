require_relative "../migrate_helpers"

class RemoveOrderDesignParamsFromOrder < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  COLUMNS = %i[x y wx wy rotation].freeze

  def up
    if_table_exists :orders do
      COLUMNS.each { |column| remove_column :orders, column, :integer, if_exists: true }
    end
  end

  def down
    if_table_exists :orders do
      COLUMNS.each { |column| add_column :orders, column, :integer, if_not_exists: true }
    end
  end
end