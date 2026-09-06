require "redcarpet"

class MarkdownService
  RENDERER_OPTIONS = {
    filter_html: true,
    hard_wrap: true,
    link_attributes: { rel: "nofollow noopener", target: "_blank" },
    safe_links_only: true,
    with_toc_data: false
  }.freeze

  EXTENSIONS = {
    autolink: true,
    tables: true,
    fenced_code_blocks: true,
    strikethrough: true,
    superscript: true,
    underline: true,
    highlight: true,
    footnotes: true,
    no_intra_emphasis: true,
    lax_spacing: true,
    space_after_headers: true
  }.freeze

  class << self
    def convert(content: "")
      return "" if content.nil? || content.strip.empty?

      renderer.render(content)
    end

    private

    def renderer
      @renderer ||= Redcarpet::Markdown.new(
        Redcarpet::Render::HTML.new(RENDERER_OPTIONS),
        EXTENSIONS
      )
    end
  end
end
