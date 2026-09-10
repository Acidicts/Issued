# == Schema Information
#
# Table name: images
#
#  id          :bigint           not null, primary key
#  devlog_type :string
#  from_time   :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  design_id   :bigint           not null
#  devlog_id   :bigint
#
# Indexes
#
#  index_images_on_design_id  (design_id)
#  index_images_on_devlog_id  (devlog_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#  fk_rails_...  (devlog_id => devlogs.id)
#
class Image < ApplicationRecord
  belongs_to :design
  belongs_to :devlog, polymorphic: true, optional: true

  has_one_attached :image_file do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 75, strip: true }
    attachable.variant :display, resize_to_limit: [ 1200, 1200 ], format: :webp, saver: { quality: 78, strip: true }
  end
  attribute :from_time, :datetime

  after_create :set_from_time
  after_create_commit :convert_svg_to_png

  def set_from_time
    self.from_time = Time.current
    self.save!
  end

  def image_for(variant_name)
    return unless image_file.attached?

    if image_file.content_type&.include?("svg")
      convert_svg_to_png
      reload
    end
    image_file.variant(variant_name)
  end

  private

  def convert_svg_to_png
    return unless image_file.attached?
    return unless image_file.content_type&.include?("svg")

    image_file.blob.open do |tempfile|
      svg_image = Vips::Image.new_from_file(tempfile.path)

      min = 800
      scale = [ min.to_f / svg_image.width, min.to_f / svg_image.height ].max
      svg_image = svg_image.resize(scale) if scale > 1

      png_path = tempfile.path + ".png"
      svg_image.write_to_file(png_path)

      image_file.attach(
        io: File.open(png_path),
        filename: image_file.filename.to_s.sub(/\.[^.]+\z/, ".png"),
        content_type: "image/png"
      )

      File.delete(png_path) if File.exist?(png_path)
    end
  rescue Vips::Error => e
    Rails.logger.error("Failed to convert SVG to PNG for Image ##{id}: #{e.message}")
  end
end
