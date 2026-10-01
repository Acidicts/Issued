class AddUniqueIndexToDesignsUserIdName < ActiveRecord::Migration[8.1]
  # Duplicates predate the index (designs defaulted to "Untitled Design"), so
  # rename the later rows instead of dropping data, then add the index.
  def up
    return if index_exists?(:designs, [ :user_id, :name ], unique: true)

    dedupe_design_names!
    add_index :designs, [ :user_id, :name ], unique: true
  end

  def down
    remove_index :designs, [ :user_id, :name ], unique: true if index_exists?(:designs, [ :user_id, :name ], unique: true)
  end

  private

  def dedupe_design_names!
    execute <<~SQL
      UPDATE designs AS d
      SET name = d.name || ' (' || dupes.rn || ')'
      FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                 PARTITION BY user_id, name
                 ORDER BY created_at ASC, id ASC
               ) AS rn
        FROM designs
      ) AS dupes
      WHERE d.id = dupes.id AND dupes.rn > 1
    SQL
  end
end