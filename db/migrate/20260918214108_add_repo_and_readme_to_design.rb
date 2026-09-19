class AddRepoAndReadmeToDesign < ActiveRecord::Migration[8.1]
  def change
    add_column :designs, :repo, :text
    add_column :designs, :readme, :text
  end
end
