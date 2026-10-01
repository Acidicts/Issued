class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants, if_not_exists: true do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :printful_id
      t.integer :cost

      t.timestamps
    end
  end
end
