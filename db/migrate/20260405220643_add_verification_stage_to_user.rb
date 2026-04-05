class AddVerificationStageToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :veri_level, :integer
  end
end
