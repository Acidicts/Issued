require "test_helper"

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

  test "should create design" do
    assert_difference("Design.count", 1) do
      post designs_path, params: {
        design: { name: "New Test", description: "Created from test" }
      }
    end

    design = Design.order(:created_at).last
    assert_redirected_to design_path(design)
  end

  test "should update design" do
    patch design_path(@design), params: {
      design: { name: "Updated" }
    }

    assert_redirected_to design_path(@design)
    assert_equal "Updated", @design.reload.name
  end
end
