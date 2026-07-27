class FixGuideColumnOnUsers < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE users SET guide = false WHERE guide IS NULL"
    change_column_default :users, :guide, false
    change_column_null :users, :guide, false
  end

  def down
    change_column_null :users, :guide, true
    change_column_default :users, :guide, nil
  end
end
