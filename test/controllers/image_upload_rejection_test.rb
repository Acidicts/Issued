require "test_helper"

# A file that is not an image must be reported back to the user, not blow up.
class ImageUploadRejectionTest < ActionDispatch::IntegrationTest
  HTML = "<html><body><script>alert(1)</script></body></html>"

  test "designs#create reports a non-image upload instead of raising" do
    sign_in_as users(:one)

    assert_nothing_raised do
      post designs_path, params: { design: { name: "Test", description: "d", image: html_upload } }
    end

    assert_response :redirect
    assert flash[:alert].present?, "the user should be told the image was rejected"
    assert_match(/not an accepted image type/i, flash[:alert], "and why it was rejected")
    # internal loader names should not leak into the message shown to the user
    assert_no_match(/VipsForeignLoad|libvips/i, flash[:alert])
  end

  test "devlogs#create reports a non-image upload instead of raising" do
    sign_in_as users(:one)
    design = designs(:one)

    assert_nothing_raised do
      post devlogs_path, params: { devlog: { design_id: design.id, title: "t", body: "b", time: 3600, image: html_upload } }
    end

    assert_response :redirect
  end

  private

  def html_upload
    Rack::Test::UploadedFile.new(StringIO.new(HTML), "text/html", original_filename: "payload.html")
  end
end
