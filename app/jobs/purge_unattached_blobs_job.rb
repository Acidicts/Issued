class PurgeUnattachedBlobsJob < ApplicationJob
  queue_as :default

  # A direct upload creates the blob before the form is submitted, so a reviewer
  # who picks a video and then navigates away leaves an object in the bucket that
  # no record ever points at. Nothing else reclaims those, so sweep them here.
  #
  # The age cutoff keeps the sweep from deleting a blob out from under a form
  # that is still open and mid-upload.
  def perform(older_than: 1.day)
    cutoff = older_than.is_a?(ActiveSupport::Duration) ? older_than.ago : older_than

    ActiveStorage::Blob
      .unattached
      .where(created_at: ..cutoff)
      .find_each { |blob| blob.purge }
  end
end
