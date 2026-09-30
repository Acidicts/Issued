require "test_helper"

# End-to-end: an SVG upload that tries to read a local file must not end up as stored
# markup or a rendered copy of that file's pixels.
class SvgUploadE2ETest < ActiveSupport::TestCase
  EVIL = <<~SVG
    <?xml version="1.0"?>
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="128" height="128">
      <image xlink:href="file:///#{Rails.root}/tmp/verify/secret.png" width="128" height="128"/>
    </svg>
  SVG

  VERIFY_DIR = Rails.root.join("tmp/verify")

  setup do
    FileUtils.mkdir_p(VERIFY_DIR)
  end

  test "an svg naming a local file is rasterised without that file's contents" do
    require "vips"
    secret = Vips::Image.black(64, 64).add([ 255, 0, 0 ]).cast("uchar")
    secret.write_to_file(VERIFY_DIR.join("secret.png").to_s)

    design = designs(:one)
    image = design.images.new(image_file: { io: StringIO.new(EVIL), filename: "evil.svg", content_type: "image/svg+xml" })

    # Either the upload is refused, or it is accepted as a flattened PNG. It must never
    # remain a document that still names the local file.
    accepted = image.save

    unless accepted
      assert image.errors[:image_file].any?, "rejection should explain itself"
    else
      assert_equal "image/png", image.image_file.content_type
      stored = image.image_file.download
      assert_no_match(/file:\/\//, stored, "stored blob still references the local file")

      # The proof: the red square only exists in secret.png, so red pixels in the
      # rendered output would mean the local file was read and served back.
      rendered = Vips::Image.new_from_buffer(stored, "").colourspace("srgb")
      red, green, blue = [ rendered[0].avg, rendered[1].avg, rendered[2].avg ].map(&:to_f)
      assert_not(red > green + 30 && red > blue + 30,
        "rendered output is red: the local file's pixels were read and returned")
    end
  ensure
    FileUtils.rm_f(VERIFY_DIR.join("secret.png"))
  end

  test "an svg labelled as png is still treated as a document" do
    # The old guard was content_type.include?("svg"), which this slips straight past.
    image = designs(:one).images.new(
      image_file: { io: StringIO.new(EVIL), filename: "sneaky.png", content_type: "image/png" }
    )
    image.save

    assert_not_equal "image/svg+xml", image.image_file&.content_type
    if image.persisted?
      assert_no_match(/file:\/\//, image.image_file.download)
    end
  end

  test "a non-image upload is rejected" do
    image = designs(:one).images.new(
      image_file: { io: StringIO.new("<html><script>alert(1)</script></html>"),
                    filename: "payload.html", content_type: "text/html" }
    )

    assert_not image.valid?, "an html upload should not be accepted as an image"
    assert image.errors[:image_file].any?
  end

  test "a legitimate svg is still accepted and flattened to a working png" do
    require "vips"
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
        <circle cx="100" cy="100" r="80" fill="green"/>
      </svg>
    SVG

    image = designs(:one).images.new(
      image_file: { io: StringIO.new(svg), filename: "logo.svg", content_type: "image/svg+xml" }
    )
    assert image.save, "a benign svg should be accepted: #{image.errors.full_messages}"

    assert_equal "image/png", image.image_file.content_type
    rendered = Vips::Image.new_from_buffer(image.image_file.download, "").colourspace("srgb")
    green, red, blue = [ rendered[1].avg, rendered[0].avg, rendered[2].avg ].map(&:to_f)
    assert(green > red + 30 && green > blue + 30, "expected the green circle to survive rasterising")
  end
end
