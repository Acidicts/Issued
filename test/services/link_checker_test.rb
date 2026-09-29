require "test_helper"

class LinkCheckerTest < ActiveSupport::TestCase
  # Endpoints that must never be reachable from a user-supplied repo/readme link.
  INTERNAL_TARGETS = [
    "http://169.254.169.254/latest/meta-data/",  # cloud metadata
    "http://metadata.google.internal/computeMetadata/v1/",
    "http://127.0.0.1:9292/up",
    "http://localhost:3000/",
    "http://[::1]:9292/",
    "http://[::ffff:127.0.0.1]/",
    "http://10.0.0.5/admin",
    "http://172.17.0.2/docker",
    "http://192.168.1.1/",
    "http://100.64.0.1/",
    "http://0.0.0.0/",
    "http://[fd00::1]/",
    "http://[fe80::1]/"
  ].freeze

  # Non-http(s) schemes are a request-forgery primitive of their own.
  UNSUPPORTED_SCHEMES = [
    "file:///etc/passwd",
    "gopher://127.0.0.1:11211/",
    "ftp://example.com/",
    "javascript:alert(1)"
  ].freeze

  test "refuses internal and link-local targets" do
    INTERNAL_TARGETS.each do |url|
      assert_not LinkChecker.reachable?(url), "#{url} should not be reachable"
    end
  end

  test "refuses schemes other than http and https" do
    UNSUPPORTED_SCHEMES.each do |url|
      assert_not LinkChecker.reachable?(url), "#{url} should not be reachable"
    end
  end

  test "refuses malformed, empty and non-string input" do
    [ "", "   ", nil, "http://", "not a url", "://nope" ].each do |url|
      assert_not LinkChecker.reachable?(url), "#{url.inspect} should not be reachable"
    end
  end

  test "does not issue a request to a loopback listener" do
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    hit = false
    thread = Thread.new do
      begin
        client = server.accept
        hit = true
        client.close
      rescue StandardError
        nil
      end
    end

    assert_not LinkChecker.reachable?("http://127.0.0.1:#{port}/secret")
    sleep 0.2
    thread.kill
    server.close

    assert_not hit, "the loopback listener should never have been contacted"
  end

  test "classifies addresses correctly" do
    checker = LinkChecker.new("https://example.test")

    %w[8.8.8.8 1.1.1.1 140.82.121.4 2606:4700::1111 ::ffff:8.8.8.8].each do |address|
      assert checker.send(:public_address, address), "#{address} should be allowed"
    end

    %w[127.0.0.1 10.1.2.3 192.168.0.5 172.20.0.1 169.254.169.254 100.100.100.200
       ::1 fc00::abcd ::ffff:127.0.0.1 0.0.0.0 255.255.255.255 224.0.0.1
       192.0.2.55 198.18.0.1 203.0.113.9 240.0.0.1 2002::1].each do |address|
      assert_nil checker.send(:public_address, address), "#{address} should be blocked"
    end
  end
end
