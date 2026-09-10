# == Schema Information
#
# Table name: products
#
#  id          :bigint           not null, primary key
#  cost        :integer
#  description :text
#  enabled     :boolean
#  image_wx    :integer          default(0), not null
#  image_wy    :integer          default(0), not null
#  image_x     :integer          default(0), not null
#  image_y     :integer          default(0), not null
#  thread_cost :integer          default(0)
#  type        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  printful_id :integer
#
class Product < ApplicationRecord
  include CurrencyConvertible

  self.inheritance_column = :_type_disabled

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 75, strip: true }
    attachable.variant :display, resize_to_limit: [ 1200, 1200 ], format: :webp, saver: { quality: 78, strip: true }
  end

  after_create_commit :convert_svg_to_png
  after_update_commit :convert_svg_to_png

  has_many :orders, dependent: :destroy
  has_many :variants, dependent: :destroy
  has_many :print_areas, dependent: :destroy

  accepts_nested_attributes_for :variants, allow_destroy: true

  attribute :description, :string, default: ""
  attribute :printful_id, :integer, default: nil
  attribute :enabled, :boolean, default: true

  REGIONS = {
    "US"    => "United States",
    "EU"    => "Europe",
    "EU_LV" => "Latvia",
    "UK"    => "United Kingdom"
  }.freeze

  def cost_usd
    self.cost
  end

  def cost_gbp
    usd_to_gbp(self.cost)
  end

  def check_stock
    data = PrintfulService.check_variants_stock(self.printful_id)
    printful_ids = variants.pluck(:printful_id)
    data[:variants].each do |variant|
      variant_obj = variants.find { |v| v.printful_id == variant["id"] }
      next unless variant_obj

      Array(variant["availability_status"]).each do |entry|
        region = entry["region"]
        status = entry["status"]
        next unless REGIONS.key?(region)

        variant_obj.set_stock(region, status == "in_stock")
      end
    end
  end

  def image_for(variant_name)
    return unless image.attached?

    if image.content_type&.include?("svg")
      convert_svg_to_png
      reload
    end
    image.variant(variant_name)
  end

  private

  def convert_svg_to_png
    return unless image.attached?
    return unless image.content_type&.include?("svg")

    image.blob.open do |tempfile|
      svg_image = Vips::Image.new_from_file(tempfile.path)

      min = 800
      scale = [ min.to_f / svg_image.width, min.to_f / svg_image.height ].max
      svg_image = svg_image.resize(scale) if scale > 1

      png_path = tempfile.path + ".png"
      svg_image.write_to_file(png_path)

      image.attach(
        io: File.open(png_path),
        filename: image.filename.to_s.sub(/\.[^.]+\z/, ".png"),
        content_type: "image/png"
      )

      File.delete(png_path) if File.exist?(png_path)
    end
  rescue Vips::Error => e
    Rails.logger.error("Failed to convert SVG to PNG for Product ##{id}: #{e.message}")
  end
end
