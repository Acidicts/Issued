require "test_helper"

class HackclubCDNServiceTest < ActiveSupport::TestCase
  def uploaded_file(filename:, content_type:, content: "bytes")
    Rack::Test::UploadedFile.new(StringIO.new(content), content_type, original_filename: filename)
  end

  test "multipart body carries the uploaded bytes and content type" do
    file = uploaded_file(filename: "clip.mp4", content_type: "video/mp4", content: "VIDEO-BYTES")

    body = HackclubCDNService.new.send(:multipart_body, file)

    assert_includes body, "VIDEO-BYTES"
    assert_includes body, "Content-Type: video/mp4"
  end

  test "multipart body strips characters that break the filename header" do
    file = uploaded_file(filename: 'my "final".mp4', content_type: "video/mp4", content: "VIDEO-BYTES")

    body = HackclubCDNService.new.send(:multipart_body, file)

    assert_includes body, 'filename="my final.mp4"'
    refute_includes body, 'filename="my "final".mp4"'
  end

  test "safe_filename keeps the basename and drops header-breaking characters" do
    service = HackclubCDNService.new

    assert_equal "clip.mp4", service.send(:safe_filename, "../../tmp/clip.mp4")
    assert_equal "my final.mp4", service.send(:safe_filename, 'my "final".mp4')
    assert_equal "upload", service.send(:safe_filename, "")
  end
end
