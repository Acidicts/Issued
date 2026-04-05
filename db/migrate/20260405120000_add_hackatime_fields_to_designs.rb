class AddHackatimeFieldsToDesigns < ActiveRecord::Migration[8.1]
  def change
    add_column :designs, :hackatime_project, :string
    add_column :designs, :hackatime_seconds, :integer
    add_index :designs, :hackatime_project, unique: true
  end
end
