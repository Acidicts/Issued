require "vips"

# Turns an untrusted attachment into a raster we are willing to serve.
#
# Everything that reaches libvips goes through here, because libvips will happily
# dereference whatever an uploaded document points at. SVG bytes are sanitised by
# SvgSanitizer first (which is why config/initializers/vips.rb still has to re-enable
# the SVG loader libvips disables by default); raster formats cannot name another
# resource, so they only need a content-type check.
class RasterImageService
  class UnprocessableImage < StandardError; end

  # Formats we are prepared to hand to libvips. Deliberately excludes SVG, which
  # takes the sanitising path, and anything that is not an image at all.
  RASTER_CONTENT_TYPES = %w[
    image/png image/jpeg image/jpg image/gif image/webp image/avif image/tiff
    image/bmp image/heic image/heif
  ].freeze

  MAX_UPLOAD_BYTES = 25.megabytes

  # libvips will happily allocate whatever a file claims to be; cap the decoded
  # pixel count so a small upload cannot pin memory.
  MAX_PIXELS = 50_000_000

  # Smallest edge we bother upscaling a converted SVG to.
  OUTPUT_MIN_DIMENSION = 800

  # Returned untouched for raster uploads, replaced with a PNG for SVG.
  Result = Struct.new(:data, :content_type, :filename, :converted, keyword_init: true)

  def self.call(...)
    new(...).call
  end

  def initialize(attachment)
    @attachment = attachment
  end

  def call
    bytes = read_bytes
    raise UnprocessableImage, "file is empty" if bytes.blank?

    if SvgSanitizer.svg_like?(bytes)
      convert_svg(bytes)
    else
      verify_raster!(bytes)
      Result.new(data: bytes, content_type: @attachment.content_type, converted: false)
    end
  rescue SvgSanitizer::UnsafeSvg => e
    raise UnprocessableImage, "That SVG could not be used: #{e.message}"
  end

  private

  # Active Storage only pushes the bytes to the service once the owning record is
  # saved, so a brand new attachment has nothing to download and the content lives in
  # the pending change. Both shapes have to be readable, because this runs from a
  # validation callback on the way in and from a normal save afterwards.
  def read_bytes
    blob = @attachment.blob
    return blob.download if blob && blob.service.exist?(blob.key)

    read_attachable(pending_attachable)
  end

  def pending_attachable
    change = @attachment.record.attachment_changes[@attachment.name]
    change&.attachable
  end

  def read_attachable(attachable)
    case attachable
    when Hash then slurp(attachable[:io])
    when String then File.binread(attachable) if File.exist?(attachable)
    when Pathname then slurp(attachable.open)
    else slurp(attachable)
    end
  end

  def slurp(io)
    return nil if io.nil?
    # A form upload arrives as a tempfile wrapper, a direct test upload as the file
    # itself, and a hash-built attachment as a StringIO.
    source = io.respond_to?(:tempfile) ? io.tempfile : io
    source = source.path if source.respond_to?(:path) && !source.respond_to?(:read)

    return File.binread(source) if source.is_a?(String) || source.is_a?(Pathname)
    return nil unless source.respond_to?(:read)

    source.rewind if source.respond_to?(:rewind)
    source.read
  rescue SystemCallError
    nil
  end

  def convert_svg(bytes)
    sanitized = SvgSanitizer.call(bytes)
    image = Vips::Image.new_from_buffer(sanitized, "")
    guard_pixel_count!(image)

    scale = OUTPUT_MIN_DIMENSION.to_f / [ image.width, image.height ].min
    image = image.resize(scale) if scale > 1

    Result.new(
      data: image.write_to_buffer(".png"),
      content_type: "image/png",
      filename: png_filename,
      converted: true
    )
  rescue Vips::Error => e
    # The libvips message names internal loaders; the user only needs to know it failed.
    Rails.logger.warn("SVG rasterising failed: #{e.message}")
    raise UnprocessableImage, "That SVG could not be rendered."
  end

  def verify_raster!(bytes)
    unless RASTER_CONTENT_TYPES.include?(@attachment.content_type.to_s.downcase)
      raise UnprocessableImage,
        "#{@attachment.content_type.presence || 'unknown content type'} is not an accepted image type"
    end
    raise UnprocessableImage, "image is too large" if bytes.bytesize > MAX_UPLOAD_BYTES

    guard_pixel_count!(Vips::Image.new_from_buffer(bytes, ""))
  rescue Vips::Error => e
    Rails.logger.warn("Image could not be read: #{e.message}")
    raise UnprocessableImage, "That file could not be read as an image."
  end

  def guard_pixel_count!(image)
    if image.width.to_i * image.height.to_i > MAX_PIXELS
      raise UnprocessableImage, "image has too many pixels"
    end
  end

  def png_filename
    base = @attachment.filename.to_s.sub(/\.[^.]+\z/, "").strip
    base = "image" if base.empty?
    "#{base}.png"
  end
end
