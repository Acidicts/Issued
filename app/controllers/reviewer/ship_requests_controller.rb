class Reviewer::ShipRequestsController < Reviewer::ReviewerController
  VIDEO_CONTENT_TYPES = /\Avideo\//i
  VIDEO_EXTENSIONS = %w[.mp4 .webm .mov .m4v].freeze

  def index
    @ship_requests = ShipRequest.joins(design: :user).pluck("designs.id", "ship_requests.status", "designs.name", "ship_requests.id", "users.name", "users.id")
  end

  def show
    @ship_request = ShipRequest.includes(review: [ :user, { proof_file_attachment: :blob } ]).find(params[:id])
  end

  def edit
  end

  def update
    unless current_user.reviewer?
      redirect_to reviewer_ship_requests_path, alert: "You do not have access to the reviewer dashboard."
      return
    end

    ship_request = ShipRequest.find(params[:id])
    status_set = { "Approve" => "approved", "Reject" => "rejected", "Elevate" => "elevated" }[params[:status_set]]

    if status_set.nil?
      redirect_to reviewer_ship_request_path(ship_request), alert: "Failed to submit: no status selected"
      return
    end

    if status_set == "elevated"
      ShipRequest.transaction do
        ship_request.status = "elevated"

        unless ship_request.save
          error = "Failed to submit review"
          raise ActiveRecord::Rollback
        end

        ship_request.review&.destroy
        ship_request.ship.destroy if ship_request.ship && "elevated".eql?(status_set)

        redirect_to design_path(ship_request.design), notice: "Successfully elevated ship request"
        return
      end
    end

    if status_set == ship_request.status || ship_request.elevated?
      redirect_to reviewer_ship_request_path(ship_request), alert: "Failed to submit: already set or elevated"
      return
    end

    unless ship_request.pending? || current_user.admin?
      redirect_to reviewer_ship_request_path(ship_request), alert: "Status is not pending"
      return
    end

    proof = params.dig(:ship_request, :proof)
    if proof.blank?
      redirect_to reviewer_ship_request_path(ship_request), alert: "Requires Proof of Review"
      return
    end

    # A direct upload posts back the signed id of a blob the browser has already
    # sent straight to the storage service, so the bytes never pass through this
    # process. Without that JS the browser posts the file itself instead, and the
    # upload happens further down inside the transaction.
    direct_upload = proof.is_a?(String)
    signed_blob = ActiveStorage::Blob.find_signed(proof) if direct_upload

    if direct_upload
      if signed_blob.blank?
        redirect_to reviewer_ship_request_path(ship_request), alert: "Proof upload expired, please upload it again"
        return
      end

      unless video_blob?(signed_blob)
        redirect_to reviewer_ship_request_path(ship_request), alert: "Proof must be a video file (mp4, webm or mov)"
        return
      end
    elsif !video_upload?(proof)
      redirect_to reviewer_ship_request_path(ship_request), alert: "Proof must be a video file (mp4, webm or mov)"
      return
    end

    error = nil
    proof_blob = nil

    begin
      ShipRequest.transaction do
        ship_request.status = status_set

        unless ship_request.save
          error = "Failed to submit review"
          raise ActiveRecord::Rollback
        end

        ship_request.review&.destroy
        ship_request.ship.destroy if ship_request.ship && "rejected".eql?(status_set)

        if truthy?(params.dig(:ship_request, :make_comment))
          ship_request.comments.create(user: current_user, body: "#{current_user.name} set #{ship_request.title} to #{status_set}")
        end

        ship_request.create_ship(title: ship_request.title, body: ship_request.body) if status_set == "approved"

        if direct_upload
          proof_blob = signed_blob
        else
          proof.tempfile.rewind
          proof_blob = ActiveStorage::Blob.create_and_upload!(
            io: proof.tempfile,
            filename: proof.original_filename,
            content_type: proof.content_type
          )
        end

        review = ship_request.create_review(user: current_user, reviewed: ship_request, comment: params.dig(:ship_request, :comment), proof_file: proof_blob)
        unless review&.persisted?
          error = "Failed to submit review"
          raise ActiveRecord::Rollback
        end
      end
    rescue ActiveStorage::Error, SystemCallError, IOError => e
      Rails.logger.error("Review proof upload failed: #{e.class} #{e.message}")
      error = "Proof upload failed: #{e.message}"
    end

    if error
      proof_blob&.purge
      redirect_to reviewer_ship_request_path(ship_request), alert: error
    else
      redirect_to design_path(ship_request.design), notice: "Successfully submitted review"
    end
  end

  private

  def video_upload?(proof)
    return false unless proof.respond_to?(:tempfile) && proof.tempfile&.size.to_i.positive?

    proof.content_type.to_s.match?(VIDEO_CONTENT_TYPES) ||
      VIDEO_EXTENSIONS.include?(File.extname(proof.original_filename.to_s).downcase)
  end

  def video_blob?(blob)
    blob.content_type.to_s.match?(VIDEO_CONTENT_TYPES) ||
      VIDEO_EXTENSIONS.include?(File.extname(blob.filename.to_s).downcase)
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value) || false
  end

  def ship_request_params
    params.fetch(:ship_request, {}).permit()
  end
end
