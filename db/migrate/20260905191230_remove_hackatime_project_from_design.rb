class RemoveHackatimeProjectFromDesign < ActiveRecord::Migration[8.1]
  def change
    remove_column :designs, :hackatime_project, :string
  end
end
