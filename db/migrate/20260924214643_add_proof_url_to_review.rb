class AddProofUrlToReview < ActiveRecord::Migration[8.1]
  def change
    add_column :reviews, :proof_url, :text
  end
end
