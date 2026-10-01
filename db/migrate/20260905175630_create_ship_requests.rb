class CreateShipRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :ship_requests, if_not_exists: true do |t|
      t.references :design, null: false, foreign_key: true
      t.integer :status

      t.timestamps
    end
  end
end
