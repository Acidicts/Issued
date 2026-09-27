class AddTypeAndValueToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :type, :string
    add_column :notifications, :value, :boolean
  end
end
