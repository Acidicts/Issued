require "test_helper"

# == Schema Information
#
# Table name: designs
#
#  id                :bigint           not null, primary key
#  description       :string           default("")
#  hackatime_project :string
#  hackatime_seconds :integer
#  name              :string           default("Untitled Design"), not null
#  status            :integer
#  time              :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_designs_on_hackatime_project  (hackatime_project) UNIQUE
#  index_designs_on_name               (name)
#  index_designs_on_user_id            (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
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

  test "belongs to user" do
    design = designs(:one)
    assert_equal users(:one), design.user
  end

  test "status enum values" do
    design = designs(:one)
    assert_equal "unshipped", design.status

    design.status = :pending
    assert_equal "pending", design.status

    design.status = :submitted
    assert_equal "submitted", design.status

    design.status = :approved
    assert_equal "approved", design.status

    design.status = :rejected
    assert_equal "rejected", design.status
  end

  test "default status is unshipped" do
    design = Design.new
    assert_equal "unshipped", design.status
  end

  test "hackatime_seconds validates numericality" do
    user = users(:one)
    design = Design.new(user: user, name: "Test", description: "Desc", hackatime_seconds: -1)
    refute design.valid?
    assert_includes design.errors[:hackatime_seconds], "must be greater than or equal to 0"
  end

  test "hackatime_seconds allows nil" do
    user = users(:one)
    design = Design.new(user: user, name: "Test", description: "Desc", hackatime_seconds: nil)
    assert design.valid?
  end

  test "hackatime_project allows blank" do
    user = users(:one)
    design = Design.new(user: user, name: "Test", description: "Desc", hackatime_project: "")
    assert design.valid?
  end

  test "elapsed_time_formatted with zero time" do
    user = users(:one)
    design = Design.new(user: user, name: "Test", description: "Desc", time: 0, hackatime_seconds: 0)
    assert_equal "00:00:00", design.elapsed_time_formatted
  end

  test "hackatime_time_formatted returns 00:00:00 when no hackatime_seconds" do
    user = users(:one)
    design = Design.new(user: user, name: "Test", description: "Desc", hackatime_seconds: nil)
    assert_equal "00:00:00", design.hackatime_time_formatted
  end

  test "hackatime_time_formatted formats seconds correctly" do
    user = users(:one)
    design = Design.new(user: user, name: "Test", description: "Desc", hackatime_seconds: 3661)
    assert_equal "01:01:01", design.hackatime_time_formatted
  end

  test "default_svg returns valid SVG string" do
    user = users(:one)
    design = Design.new(user: user, name: "Test", description: "Desc")
    svg = design.default_svg
    assert_includes svg, "<svg"
    assert_includes svg, "viewBox"
  end

  test "has many images" do
    design = designs(:one)
    assert_respond_to design, :images
  end

  test "has many orders" do
    design = designs(:one)
    assert_respond_to design, :orders
  end
end
