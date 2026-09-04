class DeleteDesignEditSession < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:design_edit_sessions)
      delete_table :design_edit_sessions
    end
  end
end
