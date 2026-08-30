require "test_helper"

# == Schema Information
#
# Table name: design_edit_sessions
#
#  id               :bigint           not null, primary key
#  activity_type    :string           default("edit")
#  duration_seconds :integer          default(0), not null
#  ended_at         :datetime
#  started_at       :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  design_id        :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_design_edit_sessions_on_design_id                 (design_id)
#  index_design_edit_sessions_on_design_id_and_created_at  (design_id,created_at)
#  index_design_edit_sessions_on_user_id                   (user_id)
#  index_design_edit_sessions_on_user_id_and_created_at    (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#  fk_rails_...  (user_id => users.id)
#
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
