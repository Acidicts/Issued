require "net/http"
require "json"
require "uri"

# PrintfulService
# ================
# Thin client around Printful's public Catalog API used to import a product
# by its Printful catalog product id.
#
# Combines three endpoints so the admin only has to supply a numeric id:
#   - GET /products/{id}            -> title, description, base price
#   - GET /mockup-generator/printfiles/{id} -> print file pixel dimensions
#   - GET /mockup-generator/templates/{id}  -> per-variant template image +
#                                               print area box (px, in the
#                                               same coordinate space as the
#                                               template image)
#
# The "front" placement is used by default since that's what most products
# in this shop use, and it's what app/models/product.rb's image_x/y/wx/wy
# fields are designed around (a single design box on a single image).
class PrintfulService
  BASE_URL = "https://api.printful.com"

  class Error < StandardError; end

  def self.api_key
    ENV["PRINTFUL_API_KEY"].presence
  end

  def self.store_id
    ENV["PRINTFUL_STORE_ID"].presence
  end

  def self.available?
    api_key.present?
  end

  # Fetches and normalizes everything needed to build a Product.
  #
  # Returns a hash:
  #   {
  #     printful_id:  Integer,
  #     title:        String,
  #     description:  String,
  #     cost:         Float,   # cheapest variant price, USD
  #     image_url:    String,  # template image to attach as Product#image
  #     image_x:      Integer, # design box, px, relative to image_url's natural size
  #     image_y:      Integer,
  #     image_wx:     Integer,
  #     image_wy:     Integer,
  #   }
  #
  # Raises PrintfulService::Error on any failure (bad id, network error,
  # missing placement, etc) with a message safe to show to an admin.
  def self.import_product(printful_id, placement: "front")
    new.import_product(printful_id, placement: placement)
  end

  def self.check_variant_stock(printful_id)
    new.check_variant_stock(printful_id)
  end

  def self.check_variants_stock(printful_id)
    new.check_variants_stock(printful_id)
  end

  def self.fetch_product_templates(printful_id)
    new.fetch_product_templates(printful_id)
  end

  VALID_PRINT_POSITIONS = %w[
    front back left right sleeve_left sleeve_right
    top bottom inside_out insidePocket inside_out_pocket
    label_outside label_inside
    zoomed close_up flat detail lifestyle
  ].freeze

  def fetch_product_templates(printful_id)
    raw = fetch_templates(printful_id)
    all_templates = raw["templates"] || []
    variant_mapping = raw["variant_mapping"] || []

    whitebg = all_templates.select { |t| t["image_url"]&.include?("whitebg") }
    all_templates = whitebg if whitebg.any?

    template_id_to_placement = {}
    variant_mapping.each do |entry|
      Array(entry["templates"]).each do |t|
        placement = t["placement"]
        template_id = t["template_id"]
        if placement.present? && VALID_PRINT_POSITIONS.include?(placement)
          template_id_to_placement[template_id] ||= placement
        end
      end
    end

    mapped_templates = all_templates.select do |template|
      template_id_to_placement.key?(template["template_id"])
    end

    mapped_templates.group_by do |template|
      template_id_to_placement[template["template_id"]]
    end.transform_values do |group|
      first = group.first
      {
        image_url: first["image_url"],
        template_width: first["template_width"],
        template_height: first["template_height"],
        print_area_width: first["print_area_width"],
        print_area_height: first["print_area_height"],
        print_area_top: first["print_area_top"],
        print_area_left: first["print_area_left"],
        is_template_on_front: first["is_template_on_front"],
        orientation: first["orientation"],
        variants: group.map { |t| { template_id: t["template_id"], background_color: t["background_color"] } }
      }
    end
  end

  def check_variants_stock(printful_id)
    product_data = fetch_product(printful_id)
    {
      variants: Array(product_data["variants"])
    }
  end

  def import_product(printful_id, placement: "front")
    raise Error, "Printful API key is not configured (set PRINTFUL_API_KEY)." unless self.class.available?
    raise Error, "Enter a Printful product id." if printful_id.blank?

    product_data   = fetch_product_catalog(printful_id)
    templates_data = fetch_templates(printful_id)

    files = Array(product_data.dig("product", "files"))

    result = pick_template(templates_data, placement: placement)
    unless result[:template]
      available = result[:available_placements].presence
      message = "No #{placement} print template found for this product."
      message += " Available placements: #{available.join(', ')}." if available
      raise Error, message
    end
    variant_id = result[:variant_id]
    template = result[:template]

    {
      printful_id: printful_id.to_i,
      type: product_data.dig("product", "title") || "Imported Product ##{printful_id}",
      description: product_data.dig("product", "description").to_s,
      cost: cheapest_price(product_data["variants"]),
      image_url: template["image_url"],
      template_width: template["template_width"].to_f,
      template_height: template["template_height"].to_f,
      print_area_left: template["print_area_left"].to_i,
      print_area_top: template["print_area_top"].to_i,
      print_area_width: template["print_area_width"].to_i,
      print_area_height: template["print_area_height"].to_i,
      variant_id: variant_id,
      variants: Array(product_data["variants"]),
      files: Array(product_data.dig("product", "files"))
    }
  end

  def check_variant_stock(printful_id)
    raise Error, "Printful API key is not configured (set PRINTFUL_API_KEY)." unless self.class.available?

    Array(fetch_variant(printful_id).dig("variant", "availability_status")).each_with_object({}) do |entry, stock|
      next unless Variant::REGIONS.key?(entry["region"])

      stock[entry["region"]] = entry["status"] == "in_stock"
    end
  end

  private

  def pick_template(templates_data, placement:)
    mapping = templates_data["variant_mapping"] || []
    templates_by_id = (templates_data["templates"] || []).index_by { |t| t["template_id"] }

    available_placements = mapping.flat_map { |e| Array(e["templates"]).map { |t| t["placement"] } }.compact.uniq

    mapping.each do |entry|
      placement_entry = Array(entry["templates"]).find { |t| t["placement"]&.start_with?(placement) }
      next unless placement_entry

      template = templates_by_id[placement_entry["template_id"]]
      return { variant_id: entry["variant_id"], template: template, available_placements: available_placements } if template
    end

    { variant_id: nil, template: nil, available_placements: available_placements }
  end

  def cheapest_price(variants)
    prices = Array(variants).filter_map { |v| v["price"]&.to_f }
    prices.min || 0.0
  end

  def fetch_product(printful_id)
    get_json("/products/#{printful_id.to_i}", store_id: self.class.store_id)
      &.fetch("result", nil)
      .tap { |result| raise Error, "Printful product ##{printful_id} was not found." unless result }
  end

  def fetch_product_catalog(printful_id)
    get_json("/products/#{printful_id.to_i}")
      &.fetch("result", nil)
      .tap { |result| raise Error, "Printful product ##{printful_id} was not found." unless result }
  end

  def fetch_variant(printful_id)
    get_json("/products/variant/#{printful_id.to_i}")
      &.fetch("result", nil)
      .tap { |result| raise Error, "Printful product variant ##{printful_id} was not found." unless result }
  end

  def fetch_templates(printful_id)
    get_json("/mockup-generator/templates/#{printful_id.to_i}", store_id: self.class.store_id)
      &.fetch("result", nil)
      .tap { |result| raise Error, "Could not load Printful templates for ##{printful_id}." unless result }
  end

  POSITIONS = %w[front back left right top bottom inside_out
                 zoomed close_up flat detail lifestyle].freeze

  def derive_position_from_url(image_url)
    path = image_url.to_s.split("?").first
    segments = path.downcase.split("/")
    segments.find { |seg| POSITIONS.any? { |pos| seg.start_with?(pos) } }
  end

  def get_json(path, params = {})
    uri = URI.parse(BASE_URL + path)
    query = params.compact
    uri.query = URI.encode_www_form(query) if query.any?

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{self.class.api_key}"
    request["Content-Type"] = "application/json"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 15) do |http|
      http.request(request)
    end

    body = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      message = body.is_a?(Hash) ? body.dig("error", "message") || body["result"] : nil
      raise Error, message.presence || "Printful API request failed (#{response.code})."
    end

    body
  rescue JSON::ParserError
    raise Error, "Printful returned an unexpected response."
  rescue Error
    raise
  rescue => error
    Rails.logger.error("PrintfulService.get_json error: #{error.class} #{error.message}")
    raise Error, "Could not reach Printful (#{error.class})."
  end
end
