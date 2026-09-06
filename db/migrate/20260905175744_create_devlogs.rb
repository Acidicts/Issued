class CreateDevlogs < ActiveRecord::Migration[8.1]
  def change
    create_table :devlogs do |t|
      t.string :title
      t.text :body
      t.references :ship_request, null: false, foreign_key: true

      t.timestamps
    end
  end
end
