require "test_helper"

# == Schema Information
#
# Table name: hackatime_projects
#
#  id         :bigint           not null, primary key
#  name       :string
#  time       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  design_id  :bigint           not null
#
# Indexes
#
#  index_hackatime_projects_on_design_id  (design_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#
class HackatimeProjectTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
