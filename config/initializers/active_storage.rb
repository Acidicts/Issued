# The :r2 service is instantiated lazily, so missing credentials would otherwise
# surface as an opaque SDK error in the middle of a reviewer's upload. Catch it
# at boot instead.
if Rails.configuration.active_storage.service.to_s == "r2"
  required = %w[R2_ACCOUNT_ID R2_BUCKET R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY]
  missing = required.reject { |name| ENV[name].present? }

  if missing.any?
    raise "Active Storage is configured to use :r2 but #{missing.join(", ")} #{missing.one? ? "is" : "are"} not set. " \
          "Add #{missing.one? ? "it" : "them"} to the environment, or set config.active_storage.service back to :local."
  end
end
