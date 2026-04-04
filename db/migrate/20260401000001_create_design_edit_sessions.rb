class CreateDesignEditSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :design_edit_sessions do |t|
      t.references :design, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.integer :duration_seconds, null: false, default: 0
      t.string :activity_type, default: "edit"

      t.timestamps
    end

    add_index :design_edit_sessions, [ :design_id, :created_at ]
    add_index :design_edit_sessions, [ :user_id, :created_at ]
  end
end
