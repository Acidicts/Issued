class AddApprovedSecondsToShipRequest < ActiveRecord::Migration[8.1]
  def change
    add_column :ship_requests, :approved_seconds, :integer, null: true
  end
end
