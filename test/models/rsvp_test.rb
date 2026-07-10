require "test_helper"

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
