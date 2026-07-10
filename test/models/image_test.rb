require "test_helper"

class ImageTest < ActiveSupport::TestCase
  test "valid image" do
    image = Image.new(design: designs(:one))
    assert image.valid?
  end

  test "belongs to design" do
    image = images(:one)
    assert_equal designs(:one), image.design
  end

  test "has image_file attachment" do
    image = images(:one)
    assert_respond_to image, :image_file
  end

  test "set_from_time callback sets from_time" do
    image = Image.create!(design: designs(:one))
    assert_not_nil image.from_time
  end
end
