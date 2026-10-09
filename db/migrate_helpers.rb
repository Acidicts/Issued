# Shared helpers for migrations that must also run against databases that
# already contain rows. Requiring this file from a migration keeps the backfill
# and constraint logic in one place instead of duplicating it per migration.
module MigrationHelpers
  # Adds a reference to a table that may already have rows.
  #
  # The column is added as nullable, existing rows are backfilled with
  # +backfill_sql+ (a SQL fragment returning a single id, or nil), and the NOT
  # NULL constraint is only applied when no nulls remain. On an empty table this
  # still ends up NOT NULL, so the resulting schema matches db/schema.rb.
  def add_reference_backfilled(table, reference, backfill_sql: nil, foreign_key: nil, **options)
    column = :"#{reference}_id"

    if foreign_key
      options[:foreign_key] = { if_not_exists: true }.merge(foreign_key.is_a?(Hash) ? foreign_key : { to_table: foreign_key })
    end

    add_reference table, reference, null: true, if_not_exists: true, **options

    backfill_reference_column(table, column, backfill_sql) if backfill_sql

    return if select_value("SELECT COUNT(*) FROM #{quote_table_name(table)} WHERE #{quote_column_name(column)} IS NULL").to_i.positive?

    change_column_null table, column, false
  end

  # Fills in a reference column using a SQL fragment that yields the new id for
  # each row, e.g. "SELECT o.design_id FROM orders AS o WHERE o.id = t.order_id".
  # The target table is aliased as +t+.
  def backfill_reference_column(table, column, backfill_sql)
    execute <<~SQL
      UPDATE #{quote_table_name(table)} AS t
      SET #{quote_column_name(column)} = (#{backfill_sql})
      WHERE #{quote_column_name(column)} IS NULL
    SQL
  end

  # Runs the block only when the table exists, so migrations stay applicable to
  # databases where an earlier schema load already created the table.
  def if_table_exists(table)
    yield if table_exists?(table)
  end
end
