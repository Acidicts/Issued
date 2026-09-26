class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reviewed, polymorphic: true, null: false
      t.text :comment

      t.timestamps
    end
  end
end
