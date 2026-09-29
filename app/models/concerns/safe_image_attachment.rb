# Normalises an untrusted Active Storage attachment before the record is saved.
#
# The stored blob is what every downstream libvips call reads, so sanitising on the
# way in is what keeps ImagePreviewService and the Active Storage variants from ever
# seeing a document that can dereference a local path or a network host.
#
# SVG is sniffed by content rather than trusting the declared content type, because a
# request can label an SVG as image/png and still get handed to a renderer.
module SafeImageAttachment
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_image_attachment
    validate :image_attachment_is_acceptable
  end

  private

  # Named to stay clear of the `image_attachment` association that
  # has_one_attached generates for Active Storage.
  def normalize_image_attachment
    return unless normalizable_image.attached?
    return if @image_attachment_normalized

    @image_attachment_normalized = true
    result = RasterImageService.call(normalizable_image)
    return unless result.converted

    normalizable_image.attach(
      io: StringIO.new(result.data.b),
      filename: result.filename,
      content_type: result.content_type
    )
  rescue RasterImageService::UnprocessableImage => e
    @image_attachment_error = e.message
  end

  def image_attachment_is_acceptable
    return if @image_attachment_error.blank?

    errors.add(normalizable_image_name, @image_attachment_error)
    @image_attachment_error = nil
  end

  # Overridden per model; each declares exactly one image attachment.
  def normalizable_image
    raise NotImplementedError
  end

  def normalizable_image_name
    :image_file
  end
end
