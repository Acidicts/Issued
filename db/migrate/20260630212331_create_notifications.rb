class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, if_not_exists: true do |t|
      t.string :time
      t.boolean :read
      t.text :body
      t.integer :priority

      t.timestamps
    end
  end
end
