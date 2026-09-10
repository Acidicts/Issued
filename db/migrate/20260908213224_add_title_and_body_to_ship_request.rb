class AddTitleAndBodyToShipRequest < ActiveRecord::Migration[8.1]
  def change
    add_column :ship_requests, :title, :string
    add_column :ship_requests, :body, :text
  end
end
