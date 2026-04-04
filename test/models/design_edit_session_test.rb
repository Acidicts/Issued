require "test_helper"

class DesignEditSessionTest < ActiveSupport::TestCase
  test "valid attributes" do
    user = users(:one)
    design = designs(:one)

    session_record = DesignEditSession.new(
      design: design,
      user: user,
      started_at: 10.minutes.ago,
      ended_at: Time.zone.now,
      duration_seconds: 600,
      activity_type: "edit"
    )

    assert session_record.valid?
  end

  test "duration cannot be negative" do
    user = users(:one)
    design = designs(:one)

    session_record = DesignEditSession.new(
      design: design,
      user: user,
      started_at: 5.minutes.ago,
      ended_at: Time.zone.now,
      duration_seconds: -1
    )

    refute session_record.valid?
    assert_includes session_record.errors[:duration_seconds], "must be greater than or equal to 0"
  end
end
