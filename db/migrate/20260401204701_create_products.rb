class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, if_not_exists: true do |t|
      t.string :type
      t.integer :cost

      t.timestamps
    end
  end
end
