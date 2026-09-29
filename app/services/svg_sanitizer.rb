require "nokogiri"

# Strips everything from an SVG document that can make the renderer reach outside
# the uploaded bytes.
#
# SVG is a document format, not a bitmap: a single <image href="..."> is enough to
# make libvips/librsvg open an arbitrary local path or issue a network request, and a
# DTD is enough for entity expansion. libvips blocks SVG loading by default for
# exactly this reason, so any SVG we do process has to pass through here first.
#
# This is a denylist rather than an allowlist because the SVG element set is large
# and a plain shape/gradient/`<use href="#id">` document is the overwhelming majority
# of legitimate uploads. Every construct below is one that can fetch a resource,
# execute, or expand; anything not on the list is inert markup that rsvg will simply
# draw.
class SvgSanitizer
  class UnsafeSvg < StandardError; end

  # Anything that reads a resource, runs code, or recurses.
  FORBIDDEN_ELEMENTS = %w[
    script foreignobject image use feimage animate animatetransform animatemotion
    animatecolor set filter handler listener audio video iframe embed object
    font-face-uri font-face-src
  ].freeze

  # Attributes that can carry a URI. Same-document fragments (#gradient) and inline
  # data URIs stay; anything that names a remote or local resource is dropped.
  URI_ATTRIBUTES = %w[href xlink:href src xlink:src data to from by values path].freeze

  # Only the SVG namespace is honoured, so <image> from a foreign namespace (XHTML's
  # <img> equivalent, for instance) cannot slip past the name check.
  SVG_NAMESPACE = "http://www.w3.org/2000/svg"

  # Defensive ceiling. librsvg already caps its own recursion, but a small ceiling
  # keeps a crafted document from becoming a long parse on a request thread.
  MAX_BYTES = 8.megabytes

  # Matches a document that actually declares itself XML or SVG. A bare `<` is not
  # enough: that would classify every HTML or text upload as a document and report it
  # back to the user as a broken SVG.
  LOOKS_LIKE_XML = /\A\s*(?:<\?xml\b|<!DOCTYPE\b|<svg\b)/i

  # Whitespace and comments are legal before the root element and must not hide it.
  LEADING_NOISE = /\A(?:\s+|<!--.*?-->)*/m

  # A leading UTF-8 BOM or whitespace is stripped before matching, so a BOM-prefixed
  # document cannot slip past the check that decides whether to sanitise.
  BYTE_ORDER_MARK = "\xEF\xBB\xBF".b.freeze

  def self.call(svg)
    new(svg).call
  end

  # True when the bytes plausibly are an SVG/XML document. Used to decide whether a
  # rasteriser needs to sanitise, independently of the declared content type.
  #
  # Anchored on a real XML/SVG marker on purpose: the case that matters is an attacker
  # sending SVG bytes while labelling them image/png, and those bytes declare
  # themselves. A real PNG or JPEG starts with a magic number instead.
  def self.svg_like?(data)
    head = data.to_s.byteslice(0, 2048).to_s.b
    head = head.byteslice(3..).to_s if head.start_with?(BYTE_ORDER_MARK)

    LOOKS_LIKE_XML.match?(head.sub(LEADING_NOISE, ""))
  end

  def initialize(svg)
    @svg = svg.to_s
  end

  def call
    raise UnsafeSvg, "SVG is empty" if @svg.strip.empty?
    raise UnsafeSvg, "SVG is too large" if @svg.bytesize > MAX_BYTES

    document = parse

    strip_external_entities(document)
    remove_forbidden_elements(document)
    scrub_attributes(document)
    strip_stylesheets(document)

    document.root ? document.to_xml(save_with: NO_DECLARATION) : ""
  end

  private

  NO_DECLARATION = Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

  def parse
    # NONET blocks network entity resolution, and NOBLANK/NOWARNING keep it quiet.
    # Nokogiri does not substitute entities unless asked, so a DTD alone is inert —
    # it is still removed below so nothing downstream has to reason about it.
    Nokogiri::XML::Document.parse(
      @svg,
      nil,
      nil,
      Nokogiri::XML::ParseOptions::NONET | Nokogiri::XML::ParseOptions::NOBLANKS
    )
  rescue Nokogiri::XML::SyntaxError => e
    raise UnsafeSvg, "SVG could not be parsed: #{e.message}"
  end

  # Drops the DOCTYPE (and with it any internal subset / entity declarations) plus
  # any processing instruction such as <?xml-stylesheet href="..."?>, which is
  # another way to pull in an external resource.
  def strip_external_entities(document)
    document.internal_subset&.remove

    document.children.each do |node|
      node.remove if node.type == Nokogiri::XML::Node::DTD_NODE ||
                      node.type == Nokogiri::XML::Node::PI_NODE
    end
  end

  def remove_forbidden_elements(document)
    document.traverse do |node|
      next unless node.element?

      name = node.name.to_s.downcase
      next unless FORBIDDEN_ELEMENTS.include?(name)
      # Only strip within SVG's own namespace; a same-named node in a foreign
      # namespace is not processed by rsvg as a resource fetch anyway.
      next unless node.namespace.nil? || node.namespace.href == SVG_NAMESPACE

      node.remove
    end
  end

  def scrub_attributes(document)
    document.traverse do |node|
      next unless node.element?

      node.attribute_nodes.each do |attribute|
        name = attribute.name.to_s.downcase

        if name == "style"
          # url(...) in a style attribute fetches.
          node.remove_attribute(attribute.name)
          next
        end

        next unless URI_ATTRIBUTES.include?(name) || name.end_with?(":href")

        unless same_document_or_data_uri?(attribute.value)
          node.remove_attribute(attribute.name)
        end
      end
    end
  end

  # <style> is where @import and url() live.
  def strip_stylesheets(document)
    document.traverse do |node|
      next unless node.element? && node.name.to_s.casecmp?("style")
      next unless node.namespace.nil? || node.namespace.href == SVG_NAMESPACE

      node.remove
    end
  end

  def same_document_or_data_uri?(value)
    value = value.to_s.strip
    return true if value.start_with?("#")
    return true if value.match?(/\Adata:image\//i)

    false
  end
end
