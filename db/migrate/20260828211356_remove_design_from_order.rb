class RemoveDesignFromOrder < ActiveRecord::Migration[8.1]
  def change
    remove_reference :orders, :design, null: false, foreign_key: true
  end
end
