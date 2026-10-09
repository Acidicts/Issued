require_relative "../migrate_helpers"

class FixGuideColumnOnUsers < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :users do
      add_column :users, :guide, :boolean, default: false, null: false, if_not_exists: true
      execute "UPDATE users SET guide = false WHERE guide IS NULL"
      change_column_default :users, :guide, false
      change_column_null :users, :guide, false
    end
  end

  def down
    if_table_exists :users do
      change_column_null :users, :guide, true
      change_column_default :users, :guide, nil
    end
  end
end
