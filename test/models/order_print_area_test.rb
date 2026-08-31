require "test_helper"

# == Schema Information
#
# Table name: order_print_areas
#
#  id               :bigint           not null, primary key
#  design_image_num :integer          default(0)
#  name             :string           default("")
#  rotation         :integer
#  x                :integer
#  xw               :integer
#  y                :integer
#  yw               :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  design_id        :bigint           not null
#  order_id         :bigint           not null
#
# Indexes
#
#  index_order_print_areas_on_design_id  (design_id)
#  index_order_print_areas_on_order_id   (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#  fk_rails_...  (order_id => orders.id)
#
class OrderPrintAreaTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
