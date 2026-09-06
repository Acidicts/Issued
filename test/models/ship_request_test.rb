require "test_helper"

# == Schema Information
#
# Table name: ship_requests
#
#  id         :bigint           not null, primary key
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  design_id  :bigint           not null
#
# Indexes
#
#  index_ship_requests_on_design_id  (design_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#
class ShipRequestTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
