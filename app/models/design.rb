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
# - has_many :orders (dependent: :destroy)
# - has_many :images (dependent: :destroy)
#
# Validations:
# - name: presence validation
# - description: presence validation
# - hackatime_project: uniqueness validation (allow blank)
# - hackatime_seconds: numericality validation (>= 0, allow nil)
# - hackatime_project_not_used_by_other_design: custom validation
#
# Enums:
# - status: { unshipped: 0, pending: 1, submitted: 2, approved: 3, rejected: 4 }
#
# Attributes:
# - status: integer with default value 0
#
# Methods:
# - elapsed_time_formatted: Formats total time as HH:MM:SS
# - total_time_seconds: Calculates total time from time and hackatime_seconds
# - hackatime_time_formatted: Formats hackatime seconds as HH:MM:SS
# - default_svg: Returns default SVG template
# - image?: Returns the most recent image file or nil
# - hackatime_project_not_used_by_other_design: Validates hackatime project uniqueness
# - formatted_time: Helper to format seconds as HH:MM:SS
#
# Scopes:
# - None
#
# Callbacks:
# - None
#

class Design < ApplicationRecord
  belongs_to :user
  has_many :orders, dependent: :destroy

  has_many :images, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true
  validates :hackatime_project, uniqueness: { allow_blank: true }
  validates :hackatime_seconds, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  validate :hackatime_project_not_used_by_other_design

  attribute :status, :integer, default: 0
  enum :status, { unshipped: 0, pending: 1, submitted: 2, approved: 3, rejected: 4 }

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

  def default_svg
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 480'><rect x='10' y='10' width='620' height='460' fill='none' stroke='#dce7f3' stroke-width='2' /></svg>"
  end

  def image_exists?
    images.order(created_at: :desc).first&.image_file.present?
  end

  def image?
    if !self.images.order(created_at: :desc).first&.image_file.nil?
      self.images.order(created_at: :desc).first&.image_file
    else
      nil
    end
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
end
