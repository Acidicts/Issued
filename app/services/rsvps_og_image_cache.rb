class RsvpsOgImageCache
  RELATIVE_PATH = "og/rsvps-count.svg".freeze

  class << self
    def public_url
      "/#{RELATIVE_PATH}"
    end

    def absolute_path
      Rails.root.join("public", RELATIVE_PATH)
    end

    def exists?
      File.exist?(absolute_path)
    end

    def stale?(max_age: 10.minutes)
      return true unless exists?

      File.mtime(absolute_path) < Time.current - max_age
    end

    def write!(count:)
      FileUtils.mkdir_p(File.dirname(absolute_path))
      temp_path = "#{absolute_path}.tmp"

      File.binwrite(temp_path, svg(count.to_i))
      FileUtils.mv(temp_path, absolute_path)
    ensure
      FileUtils.rm_f(temp_path) if temp_path && File.exist?(temp_path)
    end

    private

    def svg(count)
      label = count == 1 ? "Person RSVPed" : "People RSVPed"

      <<~SVG
        <svg width="1200" height="630" viewBox="0 0 1200 630" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Issued RSVP count">
          <defs>
            <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stop-color="#0f172a" />
              <stop offset="100%" stop-color="#1d4ed8" />
            </linearGradient>
          </defs>
          <rect width="1200" height="630" fill="url(#bg)" />
          <text x="72" y="152" fill="#93c5fd" font-size="44" font-family="Arial, Helvetica, sans-serif">Issued</text>
          <text x="72" y="300" fill="#ffffff" font-size="150" font-weight="700" font-family="Arial, Helvetica, sans-serif">#{count}</text>
          <text x="72" y="384" fill="#dbeafe" font-size="58" font-family="Arial, Helvetica, sans-serif">#{label}</text>
          <text x="72" y="560" fill="#bfdbfe" font-size="36" font-family="Arial, Helvetica, sans-serif">issued.hackclub.com/rsvp</text>
        </svg>
      SVG
    end
  end
end