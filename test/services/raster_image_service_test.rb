require "test_helper"

# An uploaded raster must survive the sanitiser unchanged, and reading its bytes must not
# depend on the default external encoding: image bytes are almost never valid UTF-8, so a
# UTF-8-tagged read makes String#blank? raise ArgumentError instead of returning false.
class RasterImageServiceTest < ActiveSupport::TestCase
  PNG_PATH = Rails.root.join("public", "icon.png")
  PNG_BYTES = File.binread(PNG_PATH)

  test "a png upload is accepted and passed through untouched" do
    image = attach_png(io: StringIO.new(PNG_BYTES))

    result = nil
    assert_nothing_raised { result = RasterImageService.call(image.image_file) }

    assert_equal PNG_BYTES.bytesize, result.data.bytesize
    assert_equal Encoding::BINARY, result.data.encoding
    assert_equal "image/png", result.content_type
    assert_not result.converted
  end

  test "attaching a png records no attachment errors" do
    image = attach_png(io: File.open(PNG_PATH))

    assert_nothing_raised { image.valid? }
    assert_empty image.errors.select { |error| error.attribute == :image_file }
  end

  test "bytes read off an upload are tagged binary, not as text" do
    image = attach_png(io: File.open(PNG_PATH))
    bytes = RasterImageService.new(image.image_file).send(:read_bytes)

    assert_equal Encoding::BINARY, bytes.encoding
    assert_not bytes.blank?, "and stay usable by the encoding-sensitive helpers"
  end

  test "an empty upload is reported, not raised as a byte error" do
    image = Image.new
    image.image_file.attach(io: StringIO.new(""), filename: "empty.png", content_type: "image/png")

    error = assert_raises(RasterImageService::UnprocessableImage) { RasterImageService.call(image.image_file) }
    assert_match(/empty/i, error.message)
  end

  private

  def attach_png(io:)
    image = Image.new
    image.image_file.attach(io: io, filename: "icon.png", content_type: "image/png")
    image
  end
end
