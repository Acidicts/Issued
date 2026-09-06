class AddTimeToDevlog < ActiveRecord::Migration[8.1]
  def change
    add_column :devlogs, :time, :integer
  end
end
