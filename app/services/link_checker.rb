require "ipaddr"
require "net/http"
require "resolv"
require "uri"

# Answers "does this user-supplied link exist?" without letting the answer be used to
# probe the network Issued is running on.
#
# `repo` and `readme` on a Design are free text and this check runs on the public
# design page, so without this the app is a request-forgery oracle pointed at whatever
# the attacker types: cloud metadata, an internal admin port, a service on localhost.
#
# Two things make the check safe:
#   1. the hostname is resolved up front and every address it resolves to must be a
#      public unicast address, and
#   2. the request is then pinned to one of those already-validated addresses with
#      Net::HTTP#ipaddr=, so a second DNS answer cannot swap a public IP for an
#      internal one between the check and the connection.
class LinkChecker
  TIMEOUT = 5

  ALLOWED_SCHEMES = %w[http https].freeze

  # Anything that is not a public unicast destination.
  BLOCKED_RANGES = [
    "0.0.0.0/8",          # "this" network
    "10.0.0.0/8",         # private
    "100.64.0.0/10",      # carrier-grade NAT
    "127.0.0.0/8",        # loopback
    "169.254.0.0/16",     # link-local, where cloud metadata endpoints live
    "172.16.0.0/12",      # private
    "192.0.0.0/24",       # IETF protocol assignments
    "192.0.2.0/24",       # TEST-NET-1
    "192.88.99.0/24",     # 6to4 relay anycast
    "192.168.0.0/16",     # private
    "198.18.0.0/15",      # benchmarking
    "198.51.100.0/24",    # TEST-NET-2
    "203.0.113.0/24",     # TEST-NET-3
    "224.0.0.0/4",        # multicast
    "240.0.0.0/4",        # reserved, includes 255.255.255.255
    "::/128",             # unspecified
    "::1/128",            # loopback
    "fc00::/7",           # unique local
    "fe80::/10",          # link-local
    "ff00::/8",           # multicast
    "2002::/16"           # 6to4
  ].map { |range| IPAddr.new(range) }.freeze

  def self.reachable?(url)
    new(url).reachable?
  end

  def initialize(url)
    @url = url.to_s.strip
  end

  def reachable?
    uri = parse
    return false unless uri

    addresses = public_addresses(uri.host)
    return false if addresses.empty?

    addresses.any? { |address| head_ok?(uri, address) }
  rescue StandardError => e
    Rails.logger.debug { "LinkChecker rejected #{@url.inspect}: #{e.class}" }
    false
  end

  private

  def parse
    return nil if @url.empty?

    uri = URI.parse(@url)
    return nil unless uri.host.present?
    return nil unless uri.scheme.to_s.downcase.in?(ALLOWED_SCHEMES)

    uri
  rescue URI::InvalidURIError
    nil
  end

  # Every address has to be public, not just the one we are about to use: a hostname
  # with a single internal answer is an internal target however we pick.
  def public_addresses(host)
    Resolv.getaddresses(host).filter_map { |address| public_address(address) }.uniq
  end

  def public_address(address)
    ip = IPAddr.new(address)
    ip = ip.native if ip.ipv6? && ip.ipv4_mapped?
    return nil if BLOCKED_RANGES.any? { |range| range.include?(ip) }

    ip.to_s
  rescue IPAddr::Error
    nil
  end

  def head_ok?(uri, address)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme.to_s.casecmp?("https")
    # Pinned: TLS SNI and certificate validation still use the hostname, but the
    # socket goes to the address we already vetted.
    http.ipaddr = address
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    http.start { |connection| connection.head(uri.request_uri) }.is_a?(Net::HTTPSuccess)
  rescue StandardError
    false
  end
end
