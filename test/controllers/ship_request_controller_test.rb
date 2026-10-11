require "test_helper"

class ShipRequestControllerTest < ActionDispatch::IntegrationTest
  test "should get next_step checks" do
    get next_step_ship_requests_path(design_id: designs(:one).id, step: "start")
    assert_response :success
  end

  test "should get next_step form" do
    get next_step_ship_requests_path(design_id: designs(:one).id, step: "checks")
    assert_response :success
  end

  test "should get next_step overview" do
    get next_step_ship_requests_path(design_id: designs(:one).id)
    assert_response :success
  end

  # Regression: reading the upload's bytes used to tag them as UTF-8, and
  # RasterImageService#call then raised ArgumentError on String#blank?, so every real
  # image upload turned a ship request into a 500 after the row was already committed.
  test "creating a ship request with a png upload does not raise" do
    sign_in_as users(:one)
    design = designs(:one)
    Devlog.create!(design: design, title: "t", body: "b", time: 60)

    with_shippable_design(design) do
      assert_nothing_raised do
        post ship_requests_path, params: {
          ship_request: {
            design_id: design.id,
            title: "ship it",
            body: "here it is",
            image: Rack::Test::UploadedFile.new(Rails.root.join("public", "icon.png"), "image/png")
          }
        }
      end
    end

    assert_response :redirect
    assert_equal 1, design.ship_requests.count, "the ship request should have been created"
  end

  private

  # can_make_ship_request? checks the repo and readme over the network, so stub the
  # reachability check rather than depending on outbound requests in a test run.
  def with_shippable_design(design)
    design.update!(repo: "https://example.com/repo", readme: "https://example.com/readme")
    original = LinkChecker.method(:reachable?)
    LinkChecker.define_singleton_method(:reachable?) { |_url| true }
    yield
  ensure
    LinkChecker.define_singleton_method(:reachable?, original)
  end
end
