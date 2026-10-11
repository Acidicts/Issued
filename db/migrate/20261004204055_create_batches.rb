class CreateBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :batches do |t|
      t.integer :number
      t.integer :status

      t.timestamps
    end
  end
end
