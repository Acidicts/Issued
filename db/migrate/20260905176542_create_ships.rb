class CreateShips < ActiveRecord::Migration[8.1]
  def change
    create_table :ships do |t|
      t.references :ship_request, null: false, foreign_key: true
      t.string :title
      t.text :body

      t.timestamps
    end
  end
end
