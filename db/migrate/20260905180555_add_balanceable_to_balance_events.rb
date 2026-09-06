class AddBalanceableToBalanceEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :balance_events, :balanceable, polymorphic: true, null: true
  end
end
