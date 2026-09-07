class DeleteDesignEditSession < ActiveRecord::Migration[8.1]
  def change
    drop_table :design_edit_sessions, if_exists: true
  end
end
