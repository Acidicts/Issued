class AddInitiatorToBalanceEvent < ActiveRecord::Migration[8.1]
  def change
    add_reference :balance_events, :initiator, null: false, foreign_key: { to_table: :users }
  end
end
