class AddKindToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :kind, :string
  end
end
