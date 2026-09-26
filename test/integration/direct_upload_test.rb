require "test_helper"

# Walks the exact sequence the browser performs for a direct upload, so the
# hand-off to the storage service stays covered without a JS driver: the browser
# asks for a signed id, PUTs the bytes straight to the service, then submits the
# signed id with the form.
class DirectUploadTest < ActionDispatch::IntegrationTest
  def sign_in_reviewer
    sign_in_as(users(:admin_user))
  end

  def request_direct_upload(filename:, content_type:, body:)
    post rails_direct_uploads_url,
      params: { blob: { filename:, content_type:, byte_size: body.bytesize, checksum: Digest::MD5.base64digest(body) } },
      as: :json

    assert_response :success
    JSON.parse(response.body)
  end

  def put_to_service(upload, body)
    uri = URI.parse(upload.fetch("url"))
    put "#{uri.path}?#{uri.query}", params: body, headers: upload.fetch("headers")
  end

  test "a proof uploaded directly reaches the review without transiting the app twice" do
    sign_in_reviewer
    ship_request = ship_requests(:one)
    video = "fake mp4 bytes"

    direct_upload = request_direct_upload(filename: "clip.mp4", content_type: "video/mp4", body: video)

    put_to_service(direct_upload.fetch("direct_upload"), video)
    assert_response :no_content

    patch reviewer_ship_request_path(ship_request),
      params: { status_set: "Reject", ship_request: { proof: direct_upload.fetch("signed_id"), comment: "bad" } }

    assert_redirected_to design_path(ship_request.design)
    ship_request.reload
    assert_equal "rejected", ship_request.status
    assert_equal "bad", ship_request.review.comment

    blob = ship_request.review.proof_file.blob
    assert_equal "clip.mp4", blob.filename.to_s
    assert_equal video.bytesize, blob.byte_size
    assert_equal video, blob.download
  end

  test "a directly uploaded file that never gets submitted is left unattached" do
    sign_in_reviewer
    video = "orphaned bytes"

    direct_upload = request_direct_upload(filename: "clip.mp4", content_type: "video/mp4", body: video)
    put_to_service(direct_upload.fetch("direct_upload"), video)
    assert_response :no_content

    blob = ActiveStorage::Blob.find_signed!(direct_upload.fetch("signed_id"))

    assert_equal 0, ActiveStorage::Attachment.where(blob_id: blob.id).count
    assert ActiveStorage::Blob.service.exist?(blob.key)
  end
end
