require "net/http"
require "json"
require "uri"

class HackclubCDNService
  BASE_URL = ENV["CDN_URL"].presence || "https://cdn.hackclub.com"
  API_PATH = ENV["CDN_API"].presence || "/api/v4"
  UPLOAD_PATH = "/upload"
  BOUNDARY = "HackclubCDN#{SecureRandom.hex(16)}"

  class Error < StandardError; end

  def self.api_key
    ENV["CDN_KEY"].presence
  end

  def self.available?
    api_key.present?
  end

  def self.upload(file)
    new.upload(file)
  end

  def self.delete(url)
    new.delete(url)
  end

  def self.me
    new.me
  end

  def me
    raise Error, "Hack Club CDN key is not configured (set CDN_KEY)." unless self.class.available?

    perform(Net::HTTP::Get.new(api_uri("/me")), "me")
  end

  def upload(file)
    raise Error, "Hack Club CDN key is not configured (set CDN_KEY)." unless self.class.available?
    raise Error, "No file to upload." if file.nil?

    request = Net::HTTP::Post.new(api_uri(UPLOAD_PATH))
    request["Content-Type"] = "multipart/form-data; boundary=#{BOUNDARY}"
    request.body = multipart_body(file)

    body = perform(request, "upload")

    url = body.is_a?(Hash) ? body["url"] : nil
    raise Error, "Hack Club CDN did not return a url." if url.blank?

    url
  end

  def delete(url)
    raise Error, "Hack Club CDN key is not configured (set CDN_KEY)." unless self.class.available?

    id = file_id(url)
    raise Error, "Could not determine a Hack Club CDN file id to delete." if id.blank?

    perform(Net::HTTP::Delete.new(api_uri("#{UPLOAD_PATH}/#{id}")), "delete")
  end

  private

  def api_uri(path = "")
    URI.parse(BASE_URL + API_PATH + path)
  end

  def file_id(url)
    path = url.to_s.strip
    return nil if path.blank?

    uri = path.match?(%r{\Ahttps?://}i) ? URI.parse(path) : nil
    (uri&.path || path).split("/").reject(&:blank?).last
  end

  def perform(request, action)
    request["Authorization"] = "Bearer #{self.class.api_key}"

    uri = request.uri
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 30) do |http|
      http.request(request)
    end

    body = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      message = body.is_a?(Hash) ? body.dig("error", "message") || body["message"] || body["result"] : nil
      raise Error, message.presence || "Hack Club CDN #{action} failed (#{response.code})."
    end

    body
  rescue JSON::ParserError
    raise Error, "Hack Club CDN returned an unexpected response."
  rescue Error
    raise
  rescue => error
    Rails.logger.error("HackclubCDNService.#{action} error: #{error.class} #{error.message}")
    raise Error, "Could not reach Hack Club CDN (#{error.class})."
  end

  def multipart_body(file)
    io, filename, content_type = normalize_file(file)
    io.rewind if io.respond_to?(:rewind)

    body = +""
    body << "--#{BOUNDARY}\r\n"
    body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
    body << "Content-Type: #{content_type}\r\n\r\n"
    body << io.read.to_s
    body << "\r\n--#{BOUNDARY}--\r\n"
    body
  end

  def normalize_file(file)
    if file.respond_to?(:tempfile)
      [ file.tempfile, safe_filename(file.original_filename), file.content_type.presence || "application/octet-stream" ]
    elsif file.respond_to?(:original_filename)
      [ file, safe_filename(file.original_filename), file.content_type.presence || "application/octet-stream" ]
    elsif file.respond_to?(:path)
      content_type = Marcel::MimeType.for(Pathname.new(file.path)) rescue "application/octet-stream"
      [ file, safe_filename(File.basename(file.path)), content_type ]
    else
      raise Error, "Unsupported file type for Hack Club CDN upload."
    end
  end

  def safe_filename(name)
    base = File.basename(name.to_s).gsub(/[\r\n"\\]/, "").strip
    base.presence || "upload"
  end
end
