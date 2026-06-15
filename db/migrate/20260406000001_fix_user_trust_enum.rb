class FixUserTrustEnum < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :trust, true
    User.where.not(trust: [ nil, 1 ]).update_all(trust: nil)
    change_column_default :users, :trust, nil
  end
end
