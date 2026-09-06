class AddDesignToDevlog < ActiveRecord::Migration[8.1]
  def change
    add_reference :devlogs, :design, null: false, foreign_key: true
  end
end
