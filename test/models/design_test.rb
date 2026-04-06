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

  test "valid with optional image attachment" do
    user = users(:one)
    design = Design.new(user: user, name: "Test Design", description: "Test desc")
    design.image.attach(
      io: StringIO.new("\x89PNG\r\n\x1a\n"),
      filename: "optional.png",
      content_type: "image/png"
    )

    assert design.valid?
  end

  test "blank svg_code purges existing svg attachment" do
    user = users(:one)
    design = Design.new(user: user, name: "Test Design", description: "Test desc")
    design.svg.attach(
      io: StringIO.new("<svg xmlns='http://www.w3.org/2000/svg'></svg>"),
      filename: "test.svg",
      content_type: "image/svg+xml"
    )

    design.svg_code = ""
    assert design.valid?
    refute design.svg.attached?
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
  test "total_time_seconds includes hackatime time" do
    user = users(:one)
    design = Design.new(user: user, name: "Test Design", description: "Test desc", time: 120, hackatime_seconds: 360)

    assert_equal 480, design.total_time_seconds
    assert_equal "00:08:00", design.elapsed_time_formatted
  end

  test "hackatime project must be unique across designs" do
    user = users(:one)
    first_design = Design.create!(user: user, name: "First", description: "First design", hackatime_project: "Hack Day", hackatime_seconds: 180)
    second_design = Design.new(user: user, name: "Second", description: "Second design", hackatime_project: "Hack Day")

    refute second_design.valid?
    assert_includes second_design.errors[:hackatime_project], "is already linked to another design"
  end
end
