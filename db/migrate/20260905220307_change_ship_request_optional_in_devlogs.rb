class ChangeShipRequestOptionalInDevlogs < ActiveRecord::Migration[8.1]
  def change
    change_column_null :devlogs, :ship_request_id, true
  end
end
