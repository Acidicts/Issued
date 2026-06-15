class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images do |t|
      t.references :design, null: false, foreign_key: true
      t.datetime :from_time

      t.timestamps
    end
  end
end
