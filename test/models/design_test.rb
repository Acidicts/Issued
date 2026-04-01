require "test_helper"
require "stringio"

class DesignTest < ActiveSupport::TestCase
  test "valid with svg attachment" do
    user = users(:one)
    design = Design.new(user: user, name: "Test Design", description: "Test desc")
    design.svg.attach(
      io: StringIO.new("<svg xmlns='http://www.w3.org/2000/svg'></svg>"),
      filename: "test.svg",
      content_type: "image/svg+xml"
    )

    assert design.valid?
  end

  test "valid with png attachment" do
    user = users(:one)
    design = Design.new(user: user, name: "Test Design", description: "Test desc")
    design.svg.attach(
      io: StringIO.new("\x89PNG\r\n\x1a\n"),
      filename: "test.png",
      content_type: "image/png"
    )

    assert design.valid?
  end

  test "invalid with non-svg png content type" do
    user = users(:one)
    design = Design.new(user: user, name: "Test Design", description: "Test desc")
    design.svg.attach(
      io: StringIO.new("hello"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    refute design.valid?
    assert_includes design.errors[:svg], "must be an SVG or PNG file"
  end

  test "invalid without description" do
    user = users(:one)
    design = Design.new(user: user, name: "", description: nil)
    refute design.valid?
    assert_includes design.errors[:description], "can't be blank"
  end
end
