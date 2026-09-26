require "test_helper"

class PurgeUnattachedBlobsJobTest < ActiveJob::TestCase
  test "purges blobs that were never attached to a record" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("orphan"), filename: "clip.mp4", content_type: "video/mp4")
    blob.update_columns(created_at: 2.days.ago)
    service = ActiveStorage::Blob.service

    assert service.exist?(blob.key), "precondition: the orphan is on the service"

    PurgeUnattachedBlobsJob.perform_now

    assert_not ActiveStorage::Blob.exists?(blob.id)
    assert_not service.exist?(blob.key)
  end

  test "leaves attached blobs alone" do
    review = Review.create!(user: users(:admin_user), reviewed: ship_requests(:one), comment: "keep me")
    review.proof_file.attach(io: StringIO.new("kept"), filename: "keep.mp4", content_type: "video/mp4")
    blob = review.proof_file.blob
    blob.update_columns(created_at: 2.days.ago)
    service = ActiveStorage::Blob.service

    PurgeUnattachedBlobsJob.perform_now

    assert ActiveStorage::Blob.exists?(blob.id)
    assert service.exist?(blob.key)
  end

  test "leaves recent unattached blobs alone so an open form is not broken" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("in flight"), filename: "clip.mp4", content_type: "video/mp4")
    service = ActiveStorage::Blob.service

    PurgeUnattachedBlobsJob.perform_now

    assert ActiveStorage::Blob.exists?(blob.id), "a direct upload that was just created may still be in a submitted form"
    assert service.exist?(blob.key)
  end
end
