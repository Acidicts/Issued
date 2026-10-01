class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true
      t.references :design, null: false, foreign_key: true
      t.integer :status

      t.timestamps
    end
  end
end
