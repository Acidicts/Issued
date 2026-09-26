require "test_helper"

class Reviewer::ShipRequestsControllerTest < ActionDispatch::IntegrationTest
  def with_failing_upload(message = "no space left on device")
    service = ActiveStorage::Blob.service
    original = service.method(:upload)
    service.define_singleton_method(:upload) { |*| raise IOError, message }
    yield
  ensure
    service.define_singleton_method(:upload, original)
  end

  def upload_file
    Rack::Test::UploadedFile.new(StringIO.new("data"), "video/mp4", original_filename: "clip.mp4")
  end

  # Stands in for what the browser's direct upload leaves behind: a blob already
  # sitting on the service, referenced by its signed id.
  def uploaded_blob(filename: "clip.mp4", content_type: "video/mp4")
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"), filename: filename, content_type: content_type)
  end

  test "should get index" do
    sign_in_as(users(:admin_user))
    get reviewer_ship_requests_url
    assert_response :success
  end

  test "should get show" do
    sign_in_as(users(:admin_user))
    get reviewer_ship_request_url(ship_requests(:one))
    assert_response :success
  end

  test "the review form uploads proofs directly to the bucket" do
    sign_in_as(users(:admin_user))
    get reviewer_ship_request_url(ship_requests(:one))

    assert_response :success
    # Proofs are tens of megabytes, so the browser PUTs them at R2 and the form
    # only carries the signed blob id.
    assert_select "input[type=file][name='ship_request[proof]'][data-direct-upload-url]", 1
    # The status line reports progress. The wiring is pinned exactly: no action
    # may touch the submit buttons, because Active Storage re-clicks one once the
    # upload finishes and the controller reads its value to tell Approve, Reject
    # and Elevate apart.
    assert_select "[data-proof-upload-target=status]", 1
    assert_select "form[data-action=?]", [
      "submit->proof-upload#submitted",
      "direct-uploads:start->proof-upload#start",
      "direct-upload:progress->proof-upload#progress",
      "direct-uploads:end->proof-upload#finish",
      "direct-upload:error->proof-upload#failed",
      "turbo:submit-end->proof-upload#finish",
      "turbo:submit-failed->proof-upload#finish"
    ].join(" ")
  end

  test "should get edit" do
    sign_in_as(users(:admin_user))
    get edit_reviewer_ship_request_url(ship_requests(:one))
    assert_response :success
  end

  test "update requires proof" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)

    patch reviewer_ship_request_path(ship_request), params: { status_set: "Reject", ship_request: { comment: "hi" } }

    assert_redirected_to reviewer_ship_request_path(ship_request)
    assert_equal "Requires Proof of Review", flash[:alert]
    assert_equal "approved", ship_request.reload.status
  end

  test "update without a status" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)

    patch reviewer_ship_request_path(ship_request), params: { ship_request: { comment: "hi" } }

    assert_equal "Failed to submit: no status selected", flash[:alert]
    assert_equal "approved", ship_request.reload.status
  end

  test "update reports proof upload failures" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)

    with_failing_upload do
      patch reviewer_ship_request_path(ship_request), params: { status_set: "Reject", ship_request: { proof: upload_file } }
    end

    assert_equal "Proof upload failed: no space left on device", flash[:alert]
    assert_equal "approved", ship_request.reload.status
    assert_nil ship_request.review
  end

  test "update stores the proof and applies the status" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)

    patch reviewer_ship_request_path(ship_request), params: { status_set: "Reject", ship_request: { proof: upload_file, comment: "bad" } }

    assert_redirected_to design_path(ship_request.design)
    ship_request.reload
    assert_equal "rejected", ship_request.status
    assert ship_request.review.proof_file.attached?
    assert_equal "clip.mp4", ship_request.review.proof_file.filename.to_s
    assert_equal "bad", ship_request.review.comment
  end

  test "update rejects a proof that is not a video" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)
    text_file = Rack::Test::UploadedFile.new(StringIO.new("not a video"), "text/plain", original_filename: "notes.txt")

    patch reviewer_ship_request_path(ship_request), params: { status_set: "Reject", ship_request: { proof: text_file } }

    assert_redirected_to reviewer_ship_request_path(ship_request)
    assert_equal "Proof must be a video file (mp4, webm or mov)", flash[:alert]
    assert_equal "approved", ship_request.reload.status
    assert_nil ship_request.review
  end

  test "update rejects an empty video file" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)
    empty_file = Rack::Test::UploadedFile.new(StringIO.new(""), "video/mp4", original_filename: "clip.mp4")

    patch reviewer_ship_request_path(ship_request), params: { status_set: "Reject", ship_request: { proof: empty_file } }

    assert_equal "Proof must be a video file (mp4, webm or mov)", flash[:alert]
    assert_equal "approved", ship_request.reload.status
    assert_nil ship_request.review
  end

  test "update only comments when make_comment is checked" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)

    patch reviewer_ship_request_path(ship_request),
      params: { status_set: "Reject", ship_request: { proof: upload_file, comment: "bad", make_comment: "0" } }

    assert_equal 0, ship_request.reload.comments.count

    patch reviewer_ship_request_path(ship_request),
      params: { status_set: "Approve", ship_request: { proof: upload_file, comment: "good", make_comment: "1" } }

    assert_equal 1, ship_request.reload.comments.count
  end

  test "update leaves the status untouched when the review cannot be created" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)
    original = ShipRequest.instance_method(:create_review)
    ShipRequest.define_method(:create_review) { |*| Review.new }

    begin
      patch reviewer_ship_request_path(ship_request), params: { status_set: "Reject", ship_request: { proof: upload_file } }
    ensure
      ShipRequest.define_method(:create_review, original)
    end

    assert_redirected_to reviewer_ship_request_path(ship_request)
    assert_equal "Failed to submit review", flash[:alert]
    assert_equal "approved", ship_request.reload.status
    assert_equal 0, ActiveStorage::Blob.count
  end

  test "update stores a proof that was uploaded directly" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)
    blob = uploaded_blob

    patch reviewer_ship_request_path(ship_request),
      params: { status_set: "Reject", ship_request: { proof: blob.signed_id, comment: "bad" } }

    assert_redirected_to design_path(ship_request.design)
    ship_request.reload
    assert_equal "rejected", ship_request.status
    assert_equal blob, ship_request.review.proof_file.blob
    assert_equal "bad", ship_request.review.comment
  end

  test "update deletes the proof it replaces" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)
    old_review = Review.create!(user: users(:admin_user), reviewed: ship_request, comment: "first pass")
    old_review.proof_file.attach(io: StringIO.new("old video"), filename: "old.mp4", content_type: "video/mp4")
    old_blob = old_review.proof_file.blob
    service = ActiveStorage::Blob.service
    assert service.exist?(old_blob.key), "precondition: the old proof is on the service"

    perform_enqueued_jobs do
      patch reviewer_ship_request_path(ship_request),
        params: { status_set: "Reject", ship_request: { proof: uploaded_blob.signed_id, comment: "second pass" } }
    end

    assert_redirected_to design_path(ship_request.design)
    ship_request.reload
    refute_equal old_blob, ship_request.review.proof_file.blob
    assert_not ActiveStorage::Blob.exists?(old_blob.id), "the replaced blob row should be gone"
    assert_not service.exist?(old_blob.key), "the replaced file should be gone from storage"
  end

  test "update rejects a direct upload whose signed id has expired" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)
    blob = uploaded_blob

    patch reviewer_ship_request_path(ship_request),
      params: { status_set: "Reject", ship_request: { proof: blob.signed_id(expires_at: 1.minute.ago) } }

    assert_redirected_to reviewer_ship_request_path(ship_request)
    assert_equal "Proof upload expired, please upload it again", flash[:alert]
    assert_equal "approved", ship_request.reload.status
    assert_nil ship_request.review
  end

  test "update rejects a direct upload that is not a video" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)
    blob = uploaded_blob(filename: "notes.txt", content_type: "text/plain")

    patch reviewer_ship_request_path(ship_request),
      params: { status_set: "Reject", ship_request: { proof: blob.signed_id } }

    assert_redirected_to reviewer_ship_request_path(ship_request)
    assert_equal "Proof must be a video file (mp4, webm or mov)", flash[:alert]
    assert_equal "approved", ship_request.reload.status
    assert_nil ship_request.review
  end

  test "update purges a directly uploaded proof that never gets attached" do
    sign_in_as(users(:admin_user))
    ship_request = ship_requests(:one)
    blob = uploaded_blob
    original = ShipRequest.instance_method(:create_review)
    ShipRequest.define_method(:create_review) { |*| Review.new }

    begin
      patch reviewer_ship_request_path(ship_request),
        params: { status_set: "Reject", ship_request: { proof: blob.signed_id } }
    ensure
      ShipRequest.define_method(:create_review, original)
    end

    assert_equal "Failed to submit review", flash[:alert]
    assert_equal "approved", ship_request.reload.status
    assert_equal 0, ActiveStorage::Blob.count
    assert_not ActiveStorage::Blob.service.exist?(blob.key)
  end
end
