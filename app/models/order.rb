# == Schema Information
#
# Table name: orders
#
#  id         :bigint           not null, primary key
#  color_hex  :string
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_orders_on_product_id  (product_id)
#  index_orders_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (user_id => users.id)
#
class Order < ApplicationRecord
  belongs_to :user
  belongs_to :product

  attribute :step, default: 3

  enum :status, { pending: 0, processing: 1, production: 2, completed: 3, cancelled: 4, user_cancelled: 5 }
  enum :step, { config: 0, design: 1, complete: 2, pending: 3 }, prefix: true

  attribute :color_hex, :string, default: ""
  attribute :print_areas, :json, default: {}

  has_one_attached :preview_image
  has_many :order_print_areas, dependent: :destroy

  def build_print_areas_from_product
    return if print_areas.present?

    self.print_areas = product.print_areas.index_with(&:enabled?)
  end

  def active_print_area_names
    print_areas.select { |_, v| v }.keys
  end

  def active_print_area?(name)
    print_areas[name] == true
  end

  def enable_print_area(name)
    print_areas[name] = true
  end

  def disable_print_area(name)
    print_areas[name] = false
  end

  def generate_and_attach_preview
    success = false
    order_print_area = order_print_areas.first
    design = order_print_area&.design

    return unless design

    # 1. Temporarily download both images to local disk
    return unless self.product.print_areas.any?
    self.product.print_areas.first.template_image.open do |base_image_file|
      design.images.last.image_file.open do |new_image_file|
        # 2. Pass the physical tempfile paths to your service
        preview_path = ImagePreviewService.call(
          base_image_path: base_image_file.path,
          new_image_path:  new_image_file.path,
          x:               order_print_area.x,
          y:               order_print_area.y,
          wx:              order_print_area.xw,
          wy:              order_print_area.yw,
          rotation:        order_print_area.rotation || 0
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
