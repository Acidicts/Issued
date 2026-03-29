class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name
      t.integer :verified
      t.string :slack_id

      t.timestamps
    end
  end
end
