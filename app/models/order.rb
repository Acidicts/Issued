# == Schema Information
#
# Table name: orders
#
#  id         :bigint           not null, primary key
#  rotation   :integer
#  status     :integer
#  wx         :integer
#  wy         :integer
#  x          :integer
#  y          :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  design_id  :integer          not null
#  product_id :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_orders_on_design_id   (design_id)
#  index_orders_on_product_id  (product_id)
#  index_orders_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (user_id => users.id)
#
class Order < ApplicationRecord
  belongs_to :user
  belongs_to :design
  belongs_to :product

  enum :status, { pending: 0, processing: 1, production: 2, completed: 3, cancelled: 4, user_cancelled: 5 }

  attribute :x, :integer, default: 0
  attribute :y, :integer, default: 0
  attribute :wx, :integer, default: 256
  attribute :wy, :integer, default: 256

  attribute :rotation, :integer, default: 0

  has_one_attached :preview_image

  def generate_and_attach_preview
    success = false

    # 1. Temporarily download both images to local disk
    self.product.image.open do |base_image_file|
      self.design.images.last.image_file.open do |new_image_file|
        # 2. Pass the physical tempfile paths to your service
        preview_path = ImagePreviewService.call(
          base_image_path: base_image_file.path,
          new_image_path:  new_image_file.path,
          x:               self.x,
          y:               self.y,
          wx:              self.wx,
          wy:              self.wy,
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

  def user_cancel
    return unless current_user == user && pending?

    update(status: :user_cancelled)
  end

  def cancelled?
    self.status == "cancelled"
  end
end
