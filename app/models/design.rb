class Design < ApplicationRecord
  belongs_to :user
  has_many :design_edit_sessions, dependent: :destroy

  has_one_attached :svg

  validates :name, presence: true
  validates :description, presence: true
  validates :hackatime_project, uniqueness: { allow_blank: true }
  validates :hackatime_seconds, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validate :hackatime_project_not_used_by_other_design
  validate :svg_attached_and_valid_format

  enum :status, { unshipped: 0, pending: 1, submitted: 2, approved: 3, rejected: 4 }
  attribute :status, :integer, default: 0

  def elapsed_time_formatted
    formatted_time(total_time_seconds)
  end

  def total_time_seconds
    (time || 0) + (hackatime_seconds || 0)
  end

  def hackatime_time_formatted
    return "00:00:00" unless hackatime_seconds.present? && hackatime_seconds.positive?

    formatted_time(hackatime_seconds)
  end

  def attach_svg_from_text(svg_text)
    return unless svg_text.present?

    svg.attach(
      io: StringIO.new(svg_text),
      filename: "design.svg",
      content_type: "image/svg+xml"
    )
  end

  def svg_content
    return default_svg unless svg.attached?

    svg.download
  rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
    # If blob metadata exists but storage file is missing, soft-recover to default
    svg.purge rescue nil
    default_svg
  end

  def default_svg
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 480'><rect x='10' y='10' width='620' height='460' fill='none' stroke='#dce7f3' stroke-width='2' /></svg>"
  end

  private

  def hackatime_project_not_used_by_other_design
    return if hackatime_project.blank?

    existing_design = Design.where(hackatime_project: hackatime_project).where.not(id: id).exists?
    errors.add(:hackatime_project, "is already linked to another design") if existing_design
  end

  def formatted_time(seconds)
    seconds ||= 0
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def svg_attached_and_valid_format
    return unless svg.attached?

    allowed_types = [ "image/svg+xml", "image/png" ]
    unless allowed_types.include?(svg.content_type)
      errors.add(:svg, "must be an SVG or PNG file")
    end
  end
end
