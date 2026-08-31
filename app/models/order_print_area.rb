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
class OrderPrintArea < ApplicationRecord
  belongs_to :order
  belongs_to :design

  has_one_attached :preview_image

  after_create :set_design_num, if: -> { self.design.present? }

  def set_design_num
    self.update!(design_image_num: (self.design.images.count - 1).to_i)
  end

  def generate_and_attach_preview
    success = false
    design = self.design

    return unless design

    print_area = self.order.product.print_areas.find { |pa| pa.name == self.name }
    return unless print_area&.template_image

    print_area.template_image.open do |base_image_file|
      design.images[self.design_image_num || 0].image_file.open do |new_image_file|
        # 2. Pass the physical tempfile paths to your service
        preview_path = ImagePreviewService.call(
          base_image_path: base_image_file.path,
          new_image_path:  new_image_file.path,
          x:               self.x,
          y:               self.y,
          wx:              self.xw,
          wy:              self.yw,
          rotation:        self.rotation || 0
        )

        # 3. Attach the result if successful
        if preview_path
          preview_image.attach(
            io: File.open(preview_path),
            filename: "order_preview_#{id || SecureRandom.hex(4)}.png",
            content_type: "image/png"
          )

          # Clean up the generated preview file
          File.delete(preview_path) if File.exist?(preview_path)
          success = true
        end
      end
    end

    success
  end
end
