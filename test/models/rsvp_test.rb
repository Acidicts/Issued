require "test_helper"

# == Schema Information
#
# Table name: rsvps
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_rsvps_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class RsvpTest < ActiveSupport::TestCase
  test "valid rsvp" do
    rsvp = Rsvp.new(user: users(:one))
    assert rsvp.valid?
  end

  test "belongs to user" do
    rsvp = rsvps(:one)
    assert_equal users(:one), rsvp.user
  end

  test "requires user" do
    rsvp = Rsvp.new
    refute rsvp.valid?
    assert_includes rsvp.errors[:user], "must exist"
  end

  test "can be created for a user" do
    user = users(:one)
    rsvp = Rsvp.create!(user: user)
    assert_equal user, rsvp.user
    assert rsvp.persisted?
  end
end
