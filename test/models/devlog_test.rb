require "test_helper"

# == Schema Information
#
# Table name: devlogs
#
#  id              :bigint           not null, primary key
#  body            :text
#  time            :integer
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  design_id       :bigint           not null
#  ship_request_id :bigint
#
# Indexes
#
#  index_devlogs_on_design_id        (design_id)
#  index_devlogs_on_ship_request_id  (ship_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#  fk_rails_...  (ship_request_id => ship_requests.id)
#
class DevlogTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
