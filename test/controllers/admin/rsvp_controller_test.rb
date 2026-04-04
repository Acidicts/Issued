require "test_helper"
require "stringio"

class Admin::RsvpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(name: "Admin", slack_id: "UADMIN", verified: 1, ysws_eligible: false, role: :admin)
    sign_in_as(@admin)
  end

  test "should get index" do
    get admin_rsvp_url
    assert_response :success
  end

  test "imports rsvps from csv" do
    csv = <<~CSV
      slack_id,name
      UCSV001,CSV User One
      UCSV002,CSV User Two
      ,Missing Slack
    CSV

    upload = uploaded_csv(csv)

    assert_difference("Rsvp.count", 2) do
      post admin_rsvp_import_path, params: { csv_file: upload }
    end

    assert_redirected_to admin_rsvp_path
    follow_redirect!
    assert_match("Imported 2 RSVPs", response.body)
    assert(User.exists?(slack_id: "UCSV001", name: "CSV User One"))
    assert(User.exists?(slack_id: "UCSV002", name: "CSV User Two"))
  end

  test "import requires a file" do
    post admin_rsvp_import_path

    assert_redirected_to admin_rsvp_path
    follow_redirect!
    assert_match("Please choose a CSV file to import.", response.body)
  end

  def uploaded_csv(content)
    Rack::Test::UploadedFile.new(StringIO.new(content), "text/csv", original_filename: "rsvps.csv")
  end
end
