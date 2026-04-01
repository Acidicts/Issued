class Design < ApplicationRecord
  belongs_to :user
  has_many :design_edit_sessions, dependent: :destroy

  has_one_attached :svg

  validates :name, presence: true
  validates :description, presence: true
  validate :svg_attached_and_valid_format

  def elapsed_time_formatted
    formatted_time(time || 0)
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

  def formatted_time(seconds)
    seconds ||= 0
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def svg_attached_and_valid_format
    return unless svg.attached?

    allowed_types = ["image/svg+xml", "image/png"]
    unless allowed_types.include?(svg.content_type)
      errors.add(:svg, "must be an SVG or PNG file")
    end
  end
end
