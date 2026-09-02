# == Schema Information
#
# Table name: print_areas
#
#  id          :bigint           not null, primary key
#  cost        :float
#  enabled     :boolean          default(FALSE)
#  image_wx    :integer
#  image_wy    :integer
#  image_x     :integer
#  image_y     :integer
#  name        :string
#  thread_cost :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  product_id  :bigint           not null
#
# Indexes
#
#  index_print_areas_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#
class PrintArea < ApplicationRecord
  belongs_to :product
  has_one_attached :template_image
end
