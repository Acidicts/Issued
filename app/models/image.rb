# == Schema Information
#
# Table name: images
#
#  id         :bigint           not null, primary key
#  from_time  :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  design_id  :bigint           not null
#
# Indexes
#
#  index_images_on_design_id  (design_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#
class Image < ApplicationRecord
  belongs_to :design
  has_one_attached :image_file
  attribute :from_time, :datetime

  after_create :set_from_time

  def set_from_time
    self.from_time = Time.current
    self.save!
  end
end
