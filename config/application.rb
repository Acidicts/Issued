require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# DATABASE_URL is exported by the dev container and points at
# issued_development for every environment, which overrides config/database.yml
# and makes `rails test` run (and purge fixtures) against the development
# database. Ignore it outside production so database.yml stays authoritative.
if %w[development test].include?(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development")
  ENV.delete("DATABASE_URL")
end

module Issued
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Proof-of-review videos are served as-is, so nothing reads their analysis.
    # The default video/audio analyzers download the entire blob to a tempfile
    # before discovering ffprobe is missing, which for a 40MB proof means
    # re-reading the whole file on every upload. Add ffmpeg back here if you
    # ever want video duration or dimensions.
    config.active_storage.analyzers = [
      ActiveStorage::Analyzer::ImageAnalyzer::Vips,
      ActiveStorage::Analyzer::ImageAnalyzer::ImageMagick
    ]

    config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
  end
end
