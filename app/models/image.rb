# Image
# =====
# Image model representing images attached to designs.
#
# Schema:
# - id: integer (primary key)
# - design_id: integer (foreign key to designs, not null)
# - from_time: datetime (timestamp when the image was created from)
# - created_at: datetime
# - updated_at: datetime
#
# Relationships:
# - belongs_to :design (design this image belongs to)
#
# Validations:
# - None
#
# Enums:
# - None
#
# Attributes:
# - from_time: datetime (virtual attribute for image creation time)
#
# Methods:
# - set_from_time: Sets from_time to current time on creation
#
# Attachments:
# - image_file: ActiveStorage attachment for the image file
#
# Scopes:
# - None
#
# Callbacks:
# - after_create :set_from_time (sets from_time on creation)
#

class Image < ApplicationRecord
  belongs_to :design
  has_one_attached :image_file
  attribute :from_time, :datetime

  after_create :set_from_time

  def set_from_time
    self.from_time = Time.current
  end
end
