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

  test "should get new" do
    get new_design_path
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

  test "should get edit" do
    get edit_design_path(@design)
    assert_response :success
  end

  test "should update design" do
    patch design_path(@design), params: {
      design: { name: "Updated" }
    }

    assert_redirected_to design_path(@design)
    assert_equal "Updated", @design.reload.name
  end

  test "create with invalid params shows errors" do
    post designs_path, params: {
      design: { name: "", description: "" }
    }
    assert_response :unprocessable_entity
  end

  test "update with invalid params shows errors" do
    patch design_path(@design), params: {
      design: { name: "", description: "" }
    }
    assert_response :unprocessable_entity
  end

  test "unauthenticated user is redirected" do
    delete logout_url

    get designs_path
    assert_redirected_to root_path
  end

  test "owner sees their pending ship request in the devlogs stream" do
    ship_request = @design.ship_requests.create!(title: "Owner Pending Request", body: "Body")

    get design_path(@design)

    assert_response :success
    assert_includes response.body, ship_request.title
  end

  test "owner sees a ship request that already has a review" do
    ship_request = @design.ship_requests.create!(title: "Reviewed Request", body: "Body")
    Review.create!(user: users(:admin_user), reviewed: ship_request, comment: "Looks good to me")

    get design_path(@design)

    assert_response :success
    assert_includes response.body, ship_request.title
    assert_includes response.body, "Looks good to me"
  end

  test "pending ship requests are hidden from signed in non owners" do
    ship_request = @design.ship_requests.create!(title: "Hidden Request", body: "Body")

    sign_in_as(users(:two))
    get design_path(@design)

    assert_response :success
    refute_includes response.body, ship_request.title
  end
end
