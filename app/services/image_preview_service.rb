require "vips"
require "securerandom"

class ImagePreviewService
  def self.call(...)
    new(...).call
  end

  def initialize(base_image_path:, new_image_path:, x:, y:, wx:, wy:, rotation: 0)
    @base_image_path = base_image_path
    @new_image_path = new_image_path
    @x = x.to_i
    @y = y.to_i
    @wx = wx.to_i
    @wy = wy.to_i
    @rotation = rotation.to_f
  end

  def call
    base = Vips::Image.new_from_file(@base_image_path)
    overlay = Vips::Image.new_from_file(@new_image_path)

    # Ensure overlay has an alpha channel so rotations preserve transparency
    unless overlay.has_alpha?
      alpha = Vips::Image.black(overlay.width, overlay.height) + 255
      overlay = overlay.bandjoin(alpha).cast("uchar")
    end

    scale_x = @wx.to_f / overlay.width
    scale_y = @wy.to_f / overlay.height
    overlay = overlay.resize(scale_x, vscale: scale_y)

    # Pass a background color of 0 for all channels (including 0 for alpha transparency)
    unless @rotation.zero?
      overlay = overlay.similarity(angle: @rotation, background: [ 0, 0, 0, 0 ])
    end

    result = base.composite(overlay, :multiply, x: @x, y: @y)

    output_filename = "preview_#{SecureRandom.hex(8)}.png"
    output_path = Rails.root.join("tmp", output_filename).to_s

    result.write_to_file(output_path)

    output_path
  rescue Vips::Error => e
    Rails.logger.error("Vips Error in ImagePreviewService: #{e.message}")
    nil
  end
end
