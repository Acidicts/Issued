class RemoveDevlogForeignKeyFromImages < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :images, :devlogs
  end
end
