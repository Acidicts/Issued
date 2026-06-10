# Design
# =======
# Design model representing user designs with SVG graphics and metadata.
#
# Schema:
# - id: integer (primary key)
# - user_id: integer (foreign key to users)
# - name: string (design name)
# - description: text (design description)
# - time: integer (total time spent on design)
# - hackatime_project: string (Hackatime project identifier)
# - hackatime_seconds: integer (Hackatime time tracking in seconds)
# - status: integer (design status: 0=unshipped, 1=pending, 2=submitted, 3=approved, 4=rejected)
# - created_at: datetime
# - updated_at: datetime
#
# Relationships:
# - belongs_to :user (user who created the design)
# - has_many :design_edit_sessions (dependent: :destroy)
# - has_one_attached :svg (ActiveStorage attachment for SVG file)
# - has_one_attached :image (ActiveStorage attachment for preview image)
#
# Validations:
# - name: presence validation
# - description: presence validation
# - hackatime_project: uniqueness validation (allow blank)
# - hackatime_seconds: numericality validation (>= 0, allow nil)
# - hackatime_project_not_used_by_other_design: custom validation
# - svg_attached_and_valid_format: custom validation
# - image_attached_and_valid_format: custom validation
#
# Enums:
# - status: { unshipped: 0, pending: 1, submitted: 2, approved: 3, rejected: 4 }
#
# Attributes:
# - svg_code: string (virtual attribute for SVG code processing)
# - status: integer with default value 0
#
# Methods:
# - elapsed_time_formatted: Formats total time as HH:MM:SS
# - svg_empty?: Checks if SVG is empty/default
# - total_time_seconds: Calculates total time from time and hackatime_seconds
# - hackatime_time_formatted: Formats hackatime seconds as HH:MM:SS
# - attach_svg_from_text: Attaches SVG from text content
# - process_svg_code: Processes SVG code and attaches to storage
# - svg_content: Retrieves SVG content from storage or returns default
# - svg_preview_source: Gets SVG preview source for display
# - default_svg: Returns default SVG template
# - hackatime_project_not_used_by_other_design: Validates hackatime project uniqueness
# - formatted_time: Helper to format seconds as HH:MM:SS
# - svg_attached_and_valid_format: Validates SVG file format
# - image_attached_and_valid_format: Validates image file format
#
# Attachments:
# - svg: ActiveStorage attachment for SVG file (must be image/svg+xml or image/png)
# - image: ActiveStorage attachment for preview image (must be image/png or image/jpeg)
#
# Scopes:
# - None
#
# Callbacks:
# - before_validation :process_svg_code (processes SVG code before validation)
#

class Design < ApplicationRecord
  attr_accessor :svg_code

  belongs_to :user
  has_many :design_edit_sessions, dependent: :destroy

  has_one_attached :svg
  has_one_attached :image

  validates :name, presence: true
  validates :description, presence: true
  validates :hackatime_project, uniqueness: { allow_blank: true }
  validates :hackatime_seconds, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  before_validation :process_svg_code
  validate :hackatime_project_not_used_by_other_design
  validate :svg_attached_and_valid_format
  validate :image_attached_and_valid_format

  attribute :status, :integer, default: 0
  enum :status, { unshipped: 0, pending: 1, submitted: 2, approved: 3, rejected: 4 }

  def elapsed_time_formatted
    formatted_time(total_time_seconds)
  end

  def svg_empty?
    svg_content.to_s.strip == '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 480"></svg>'
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

  def process_svg_code
    return unless svg_code.present? || svg_code == ""

    if svg_code.present?
      attach_svg_from_text(svg_code)
    else
      svg.purge if svg.attached?
    end
  end

  def svg_content
    return default_svg unless svg.attached?

    svg.download
  rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
    # If blob metadata exists but storage file is missing, soft-recover to default
    svg.purge rescue nil
    default_svg
  end

  def svg_preview_source
    return svg_code if svg_code.present?
    return nil unless svg.attached?
    return nil unless svg.blob&.content_type == "image/svg+xml"

    svg.download.presence
  rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
    svg.purge rescue nil
    nil
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

  def image_attached_and_valid_format
    return unless image.attached?

    allowed_types = [ "image/png", "image/jpeg" ]
    unless allowed_types.include?(image.content_type)
      errors.add(:image, "must be a PNG or JPEG file")
    end
  end
end
