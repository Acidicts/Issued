class AddDevlogTypeToImages < ActiveRecord::Migration[8.1]
  def change
    add_column :images, :devlog_type, :string
  end
end
