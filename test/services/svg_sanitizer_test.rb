require "test_helper"

class SvgSanitizerTest < ActiveSupport::TestCase
  # Anything that makes the renderer read a resource, run code, or expand a DTD.
  ATTACKS = {
    "image element with a file:// href" => <<~SVG,
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="10" height="10">
        <image xlink:href="file:///etc/hostname" width="10" height="10"/>
      </svg>
    SVG
    "image element with an http href" => <<~SVG,
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="10" height="10">
        <image xlink:href="http://169.254.169.254/latest/meta-data/" width="10" height="10"/>
      </svg>
    SVG
    "href without the xlink prefix" => <<~SVG,
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="10" height="10">
        <image href="file:///etc/hostname" width="10" height="10"/>
      </svg>
    SVG
    "feImage pulling in a local file" => <<~SVG,
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="10" height="10">
        <filter id="f"><feImage xlink:href="file:///etc/hostname"/></filter>
        <rect width="10" height="10" filter="url(#f)"/>
      </svg>
    SVG
    "use referencing an external entity" => <<~SVG,
      <?xml version="1.0"?>
      <!DOCTYPE svg [<!ENTITY x SYSTEM "file:///etc/hostname">]>
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="10" height="10">
        <use xlink:href="&x;"/>
      </svg>
    SVG
    "style element importing a remote stylesheet" => <<~SVG,
      <?xml version="1.0"?>
      <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
        <style>@import url("http://169.254.169.254/");</style>
        <rect width="10" height="10"/>
      </svg>
    SVG
    "foreignObject embedding html" => <<~SVG,
      <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
        <foreignObject width="10" height="10">
          <body xmlns="http://www.w3.org/1999/xhtml"><img src="file:///etc/hostname"/></body>
        </foreignObject>
      </svg>
    SVG
    "animate rewriting href" => <<~SVG,
      <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
        <rect width="10" height="10"><animate attributeName="href" values="file:///etc/hostname"/></rect>
      </svg>
    SVG
    "script element" => <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
        <script>fetch("http://169.254.169.254/")</script>
        <rect width="10" height="10"/>
      </svg>
    SVG
  }.freeze

  test "strips every construct that can read a resource" do
    ATTACKS.each do |label, payload|
      # Both outcomes are safe: refusing the document outright, or returning it with
      # the dangerous construct removed. What must never happen is handing it on.
      output = begin
        SvgSanitizer.call(payload)
      rescue SvgSanitizer::UnsafeSvg
        :rejected
      end

      next if output == :rejected

      assert_no_match(/file:\/\//, output, "#{label}: file:// survived")
      assert_no_match(/xlink:href/i, output, "#{label}: xlink:href survived")
      assert_no_match(/@import/i, output, "#{label}: @import survived")
      assert_no_match(/169\.254\.169\.254/, output, "#{label}: metadata host survived")
      assert_no_match(/<script/i, output, "#{label}: script survived")
      assert_no_match(/<!ENTITY/i, output, "#{label}: entity declaration survived")
    end
  end

  test "refuses rather than passing on a document it cannot parse" do
    assert_raises(SvgSanitizer::UnsafeSvg) do
      SvgSanitizer.call("<svg><<<not really xml")
    end
  end

  test "drops the doctype so no entity can be referenced later" do
    payload = <<~SVG
      <?xml version="1.0"?>
      <!DOCTYPE svg [<!ENTITY xxe SYSTEM "file:///etc/hostname">]>
      <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><text>&xxe;</text></svg>
    SVG

    assert_no_match(/DOCTYPE/i, SvgSanitizer.call(payload))
  end

  test "keeps legitimate markup" do
    payload = <<~SVG
      <?xml version="1.0"?>
      <svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120">
        <defs><linearGradient id="g"><stop offset="0" stop-color="red"/></linearGradient></defs>
        <circle cx="60" cy="60" r="50" fill="url(#g)"/>
        <rect x="10" y="10" width="20" height="20" fill="blue"/>
      </svg>
    SVG

    sanitized = SvgSanitizer.call(payload)

    assert_match(/<circle/, sanitized)
    assert_match(/<rect/, sanitized)
    assert_match(/url\(#g\)/, sanitized, "same-document gradient reference should survive")
    assert_match(/viewBox/, sanitized)
  end

  test "rejects empty and oversized documents" do
    assert_raises(SvgSanitizer::UnsafeSvg) { SvgSanitizer.call("") }
    assert_raises(SvgSanitizer::UnsafeSvg) { SvgSanitizer.call(" " * (SvgSanitizer::MAX_BYTES + 1)) }
  end

  test "recognises svg by content rather than declared type" do
    # The attack this exists for: real SVG bytes sent with a content type that is not
    # SVG, so the old content_type.include?("svg") guard would skip sanitising.
    assert SvgSanitizer.svg_like?(%q(<svg xmlns="http://www.w3.org/2000/svg"></svg>))
    assert SvgSanitizer.svg_like?("<?xml version=\"1.0\"?><svg/>")
    assert SvgSanitizer.svg_like?("\xEF\xBB\xBF<svg/>".b)

    assert_not SvgSanitizer.svg_like?("\x89PNG\r\n\x1A\n".b)
    assert_not SvgSanitizer.svg_like?("\xFF\xD8\xFF\xE0".b)
    assert_not SvgSanitizer.svg_like?("GIF89a")
    assert_not SvgSanitizer.svg_like?("")
  end
end
