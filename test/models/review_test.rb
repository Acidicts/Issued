require "test_helper"

# == Schema Information
#
# Table name: reviews
#
#  id            :bigint           not null, primary key
#  comment       :text
#  proof_url     :text
#  reviewed_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  reviewed_id   :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_reviews_on_reviewed  (reviewed_type,reviewed_id)
#  index_reviews_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ReviewTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
