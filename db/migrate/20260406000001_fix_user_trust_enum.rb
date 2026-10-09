require_relative "../migrate_helpers"

class FixUserTrustEnum < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    return unless column_exists?(:users, :trust)

    change_column_null :users, :trust, true

    # Raw SQL rather than the User model: the column is removed by a later
    # migration, so the model can never represent this state.
    execute "UPDATE users SET trust = NULL WHERE trust IS NOT NULL AND trust <> 1"

    change_column_default :users, :trust, nil
  end

  def down
    change_column_default :users, :trust, 0 if column_exists?(:users, :trust)
  end
end
