class CreateBalanceEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :balance_events do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount
      t.string :name
      t.text :comment

      t.timestamps
    end
  end
end
