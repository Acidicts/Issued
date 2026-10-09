require_relative "../migrate_helpers"

class AddInitiatorToBalanceEvent < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    if_table_exists :balance_events do
      add_reference_backfilled :balance_events, :initiator,
        foreign_key: { to_table: :users },
        backfill_sql: "SELECT t2.user_id FROM balance_events AS t2 WHERE t2.id = t.id"
    end
  end

  def down
    if_table_exists :balance_events do
      remove_reference :balance_events, :initiator, foreign_key: { to_table: :users }
    end
  end
end
