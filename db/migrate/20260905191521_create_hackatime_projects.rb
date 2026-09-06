class CreateHackatimeProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :hackatime_projects do |t|
      t.integer :time
      t.string :name
      t.references :design, null: false, foreign_key: true

      t.timestamps
    end
  end
end
