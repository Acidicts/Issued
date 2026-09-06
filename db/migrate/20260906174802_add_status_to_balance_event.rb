class AddStatusToBalanceEvent < ActiveRecord::Migration[8.1]
  def change
    add_column :balance_events, :status, :integer
  end
end
