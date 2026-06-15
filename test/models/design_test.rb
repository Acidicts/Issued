require "test_helper"

class DesignTest < ActiveSupport::TestCase
  test "valid design" do
    user = users(:one)
    design = Design.new(user: user, name: "Test Design", description: "Test desc")

    assert design.valid?
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
