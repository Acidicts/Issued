class FixProductionSchema < ActiveRecord::Migration[8.1]
  def up
    # --- users ---
    unless column_exists?(:users, :guide)
      add_column :users, :guide, :boolean, default: false, null: false
    end

    # --- products ---
    unless column_exists?(:products, :image_x)
      add_column :products, :image_x, :integer, default: 0, null: false
      add_column :products, :image_y, :integer, default: 0, null: false
      add_column :products, :image_wx, :integer, default: 0, null: false
      add_column :products, :image_wy, :integer, default: 0, null: false
    end
    unless column_exists?(:products, :description)
      add_column :products, :description, :text
    end
    unless column_exists?(:products, :printful_id)
      add_column :products, :printful_id, :integer
    end

    # --- orders ---
    unless column_exists?(:orders, :step)
      add_column :orders, :step, :integer
    end
    unless column_exists?(:orders, :color_hex)
      add_column :orders, :color_hex, :string
    end
    unless column_exists?(:orders, :print_areas)
      add_column :orders, :print_areas, :jsonb, default: {}, null: false
    end

    # --- designs (table should exist from schema:load, but ensure it's in schema_migrations) ---
    unless column_exists?(:designs, :user_id)
      # designs table exists but might be missing the user_id column
      add_reference :designs, :user, null: false, foreign_key: true
    end

    # --- variants ---
    unless table_exists?(:variants)
      create_table :variants do |t|
        t.references :product, null: false, foreign_key: true
        t.integer :printful_id
        t.integer :cost
        t.timestamps
      end
    end
    unless column_exists?(:variants, :color_hex)
      add_column :variants, :color_hex, :string
    end
    unless column_exists?(:variants, :stock_by_region)
      add_column :variants, :stock_by_region, :jsonb, default: {}, null: false
      add_index :variants, :stock_by_region, using: :gin
    end
    unless column_exists?(:variants, :size)
      add_column :variants, :size, :integer
    end

    # --- print_areas ---
    unless table_exists?(:print_areas)
      create_table :print_areas do |t|
        t.integer :image_x
        t.integer :image_y
        t.integer :image_wx
        t.integer :image_wy
        t.references :product, null: false, foreign_key: true
        t.integer :cost
        t.integer :thread_cost
        t.string :name
        t.boolean :enabled, default: false
        t.timestamps
      end
    end

    # --- order_print_areas ---
    unless table_exists?(:order_print_areas)
      create_table :order_print_areas do |t|
        t.integer :rotation
        t.integer :x
        t.integer :y
        t.integer :xw
        t.integer :yw
        t.references :order, null: false, foreign_key: true
        t.timestamps
      end
    end
    unless column_exists?(:order_print_areas, :design_id)
      add_reference :order_print_areas, :design, null: false, foreign_key: true
    end
    unless column_exists?(:order_print_areas, :name)
      add_column :order_print_areas, :name, :string, default: ""
    end
    unless column_exists?(:order_print_areas, :design_image_num)
      add_column :order_print_areas, :design_image_num, :integer, default: 0
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
