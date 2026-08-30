module Admin
  class ProductsController < Admin::DashboardController
    before_action :require_admin
    before_action :require_login

    def index
      @products = Product.all
    end

    def show
      # Admin product details stub
    end

    def new
      return unless current_user.admin?

      @product = Product.new
    end

    def edit
      return unless current_user.admin?
      return unless params[:id]

      @product = Product.find(params[:id])
    end

    def create
      return unless current_user.admin?

      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_products_path, notice: "Product was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def new_by_printful_id
      unless current_user.admin?
        nil
      end
    end

    def import_from_printful
      return unless current_user.admin?

      data = PrintfulService.import_product(params[:printful_id])
      @product = build_product_from_printful(data)

      if @product.save
        redirect_to edit_admin_product_path(@product),
          notice: "Imported \"#{@product.description.presence || data[:type]}\" from Printful. Review the details and design placement below."
      else
        render :new_by_printful_id, status: :unprocessable_entity
      end
    rescue PrintfulService::Error => error
      @printful_error = error.message
      render :new_by_printful_id, status: :unprocessable_entity
    end

    def update
      return unless current_user.admin?
      return unless params[:id]

      product = Product.find(params[:id])

      if product.update(product_params)
        sync_print_areas(product) if params[:product][:print_areas_json].present?
        redirect_to admin_products_path, notice: "Product was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      return unless current_user.admin?
      return unless params[:id]

      product = Product.find(params[:id])
      product.destroy
      redirect_to admin_products_path, notice: "Product was successfully deleted."
    end

    private

    def product_params
      params.require(:product).permit(
        :printful_id,
        :type,
        :description,
        :cost,
        :thread_cost,
        :image,
        :print_areas_json,
        variants_attributes: [
          :color_hex,
          :id,
          :printful_id,
          :size,
          { stock_by_region: {} },
          :_destroy
        ]
        )
    end

    def sync_print_areas(product)
      print_areas_data = JSON.parse(params[:product][:print_areas_json])

      submitted_ids = print_areas_data.select { |d| d["id"].present? && !d["_destroy"] }.map { |d| d["id"] }

      product.print_areas.where.not(id: submitted_ids).destroy_all

      print_areas_data.each do |pa_data|
        next if pa_data["_destroy"]

        if pa_data["id"].present?
          pa = product.print_areas.find_by(id: pa_data["id"])
          next unless pa

          pa.update(
            name: pa_data["name"],
            image_x: pa_data["image_x"].to_i,
            image_y: pa_data["image_y"].to_i,
            image_wx: pa_data["image_wx"].to_i,
            image_wy: pa_data["image_wy"].to_i
          )
        else
          product.print_areas.create!(
            name: pa_data["name"],
            image_x: pa_data["image_x"].to_i,
            image_y: pa_data["image_y"].to_i,
            image_wx: pa_data["image_wx"].to_i,
            image_wy: pa_data["image_wy"].to_i
          )
        end
      end
    end

    def build_product_from_printful(data)
      product = Product.new(
        printful_id: data[:printful_id],
        description: data[:type],
        cost: data[:cost]
      )

      image_bytes, content_type, filename = download_image(data[:image_url])
      apply_scaled_design_box(product, data, image_bytes)

      product.image.attach(
        io: StringIO.new(image_bytes),
        filename: filename,
        content_type: content_type
      )

      Array(data[:variants]).each do |variant_data|
        product.variants.build(
          printful_id: variant_data["id"],
          size: variant_data["size"],
          color_hex: variant_data["color_code"],
          stock_by_region: stock_by_region_from_printful(variant_data)
        )
      end

      print_area_templates = PrintfulService.fetch_product_templates(product.printful_id)

      print_area_templates.each do |position, template|
        image_bytes, content_type, filename = download_image(template[:image_url])

        print_area = product.print_areas.build(
          name: position,                             # "front" / "back"
          image_x: template[:print_area_left].to_i,
          image_y: template[:print_area_top].to_i,
          image_wx: template[:print_area_width].to_i,
          image_wy: template[:print_area_height].to_i,
          enabled: true
        )

        print_area.template_image.attach(
          io: StringIO.new(image_bytes),
          filename: filename,
          content_type: content_type
        )
        apply_scaled_design_box(print_area, template, image_bytes)
      end

      product
    end

    def stock_by_region_from_printful(variant_data)
      Array(variant_data["availability_status"]).each_with_object({}) do |entry, hash|
        next unless Variant::REGIONS.key?(entry["region"])

        hash[entry["region"]] = entry["status"] == "in_stock"
      end
    end

    def download_image(image_url)
      raise PrintfulService::Error, "Printful did not return a product image." if image_url.blank?

      uri = URI.parse(image_url)
      response = Net::HTTP.get_response(uri)
      raise PrintfulService::Error, "Could not download the Printful product image." unless response.is_a?(Net::HTTPSuccess)

      filename = File.basename(uri.path).presence || "printful-product.png"
      content_type = response.content_type.presence || "image/png"

      [ response.body, content_type, filename ]
    end

    # Printful's print_area_* coordinates are relative to the template's
    # own width/height (often 3000x3000), NOT necessarily the pixel size
    # of the image file actually served at image_url (which can be a
    # smaller rendition, e.g. 1000x1000). Scale the box to match the real
    # downloaded image so it lines up correctly with app/models/product.rb's
    # image_x/y/wx/wy fields (which are natural-pixel-space of Product#image).
    def apply_scaled_design_box(product, data, image_bytes)
      actual_width, actual_height = real_image_dimensions(image_bytes)
      template_width  = data[:template_width].to_f
      template_height = data[:template_height].to_f

      scale_x = (actual_width.to_f  / template_width)  if actual_width  && template_width.positive?
      scale_y = (actual_height.to_f / template_height) if actual_height && template_height.positive?
      scale_x ||= 1.0
      scale_y ||= 1.0

      product.image_x  = (data[:print_area_left].to_i   * scale_x).round
      product.image_y  = (data[:print_area_top].to_i    * scale_y).round
      product.image_wx = (data[:print_area_width].to_i  * scale_x).round
      product.image_wy = (data[:print_area_height].to_i * scale_y).round
    end

    def real_image_dimensions(image_bytes)
      image = MiniMagick::Image.read(image_bytes)
      [ image.width, image.height ]
    rescue => error
      Rails.logger.error("PrintfulService image dimension read error: #{error.class} #{error.message}")
      [ nil, nil ]
    end
  end
end
