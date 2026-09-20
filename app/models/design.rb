require "net/http"

# == Schema Information
#
# Table name: designs
#
#  id                :bigint           not null, primary key
#  description       :string           default("")
#  devlogged_time    :integer
#  hackatime_seconds :integer
#  name              :string           default("Untitled Design"), not null
#  readme            :text
#  repo              :text
#  status            :integer
#  time              :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_designs_on_name              (name)
#  index_designs_on_user_id           (user_id)
#  index_designs_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Design < ApplicationRecord
  belongs_to :user
  has_many :order_print_areas, dependent: :destroy

  has_many :images, dependent: :destroy

  has_many :ship_requests, dependent: :destroy
  has_many :ships, through: :ship_requests

  has_many :devlogs, dependent: :destroy
  has_many :hackatime_projects, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id, message: "has already been used for one of your designs" }
  validates :description, presence: true
  validates :hackatime_seconds, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  attribute :status, :integer, default: 0

  attribute :name, :string, default: ""
  attribute :description, :string, default: ""

  enum :status, { unshipped: 0, pending: 1, submitted: 2, approved: 3, rejected: 4 }

  def sync_hackatime_projects
    self.hackatime_projects.each do |hp|
      hp.sync_hackatime_project
    end
    self.hackatime_seconds = hackatime_projects.to_a.sum(&:time)
  end

  def update_logged_time
    time = self.devlogs.sum(:time)
    self.update(devlogged_time: time)
  end

  def unlogged_time
    self.hackatime_seconds.to_i - self.devlogged_time.to_i
  end

  def can_make_devlog?
    return @can_make_devlog_result if defined?(@can_make_devlog_result)
    self.sync_hackatime_projects
    self.update_logged_time
    @can_make_devlog_result = unlogged_time >= 15 * 60
  end

  def can_ship?
    self.devlogs.where(ship_request: nil).any?
  end

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

  def latest_image
    return @latest_image if defined?(@latest_image)
    @latest_image = images.order(created_at: :desc).first
  end

  def image_exists?
    return @image_exists_result if defined?(@image_exists_result)
    @image_exists_result = latest_image&.image_file&.attached?
  end

  def can_make_ship_request?
    can_make_ship_request_checks[:success]
  end

  def check_link(link)
    uri = URI.parse(link)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      http.head(uri.request_uri)
    end
    response.is_a?(Net::HTTPSuccess)
  rescue URI::InvalidURIError, Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED
    false
  end

  def can_make_ship_request_checks
    checks = {
      "valid_repo": repo.present? && check_link(repo),
      "valid_readme": readme.present? && check_link(readme),
      "image_exists": image?,
      "description_exists": description.present?,
      "not_ship_request_exist": ship_requests.where(status: [ :pending, :elevated ]).none?
    }

    {
      "success": all_passed = checks.values.all?,
      "checks": checks
    }
  end

  def missing_checks
    checks = can_make_ship_request_checks[:checks]

    messages = {
      valid_repo: "Repo link doesn't exist",
      valid_readme: "README link doesn't exist",
      image_exists: "Design needs an image",
      description_exists: "Description is required",
      not_ship_request_exist: "A pending ship already exists"
    }

    checks.each do |key, passed|
      return messages[key] unless passed
    end

    nil
  end

  def can_make_ship_request_checks_md
    checks = can_make_ship_request_checks()[:checks]
    "
      ## Ship Checklist
      [#{checks[:valid_repo] ? "x" : " "}] Valid Repo
      [#{checks[:valid_readme] ? "x" : " "}] Valid README
      [#{checks[:image_exists] ? "x" : " "}] Image Exists
      [#{checks[:description_exists] ? "x" : " "}] Description Exists
      [#{checks[:not_ship_request_exist] ? "x" : " "}] Ship Request doesn't already exist
    "
  end

  def image?
    return @image_result if defined?(@image_result)
    if latest_image&.image_file.present?
      @image_result = images.where(devlog_type: "Devlog").order(created_at: :desc).first&.image_file
    else
      @image_result = nil
    end
  end

  private

  def formatted_time(seconds)
    seconds ||= 0
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end
end
