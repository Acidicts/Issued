require "test_helper"
require "securerandom"

class DesignsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @design = designs(:one)
    @user = @design.user

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: @user.slack_id,
      info: { name: @user.name, slack_id: @user.slack_id }
    )
    get "/auth/hackclub/callback"

    expected_user = User.find_by(slack_id: @user.slack_id)
    assert_equal expected_user.id, session[:user_id]
    assert_equal expected_user.id, @design.user_id
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:hackclub)
  end

  test "should get index" do
    get designs_path
    assert_response :success
  end

  test "should get new via editor path" do
    get editor_designs_path
    assert_response :success
  end

  test "should create design" do
    assert_difference("Design.count", 1) do
      post designs_path, params: {
        design: { name: "New Test", description: "Created from test" },
        design_svg_code: "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><rect x='0' y='0' width='10' height='10' fill='black'/></svg>",
        elapsed_seconds: 5
      }
    end

    design = Design.order(:created_at).last
    assert_redirected_to edit_design_path(design)
    assert_equal 5, design.time
    assert design.svg.attached?
  end

  test "should update design" do
    patch design_path(@design), params: {
      design: { name: "Updated" },
      design_svg_code: "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'></svg>",
      elapsed_seconds: 7
    }

    assert_redirected_to edit_design_path(@design)
    assert_equal "Updated", @design.reload.name
    assert_equal 127, @design.reload.time
  end
end
