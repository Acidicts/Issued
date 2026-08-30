class AddStepToOrder < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :step, :integer
  end
end
