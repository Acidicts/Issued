require "vips"

# libvips refuses to load SVG by default: an SVG is a document that can name a local
# path (`<image xlink:href="file:///...">`) or a network host, so parsing an untrusted
# one turns the renderer into a file-read and request-forgery primitive.
#
# We do want to accept SVG uploads and flatten them to PNG, so the loader is re-enabled
# here. That is only safe because every byte that reaches libvips goes through
# SvgSanitizer first — see SafeImageAttachment, which sanitises on the way in, so the
# stored blob is already safe by the time ImagePreviewService or an Active Storage
# variant opens it. Do not call Vips::Image.new_from_file/new_from_buffer on an
# attachment without going through RasterImageService.
Vips.block("VipsForeignLoadSvg", false)
