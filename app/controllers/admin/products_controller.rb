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
        redirect_to admin_product_path(@product), notice: "Product was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      return unless current_user.admin?
      return unless params[:id]

      product = Product.find(params[:id])
      if product.update(product_params)
        redirect_to admin_product_path(product), notice: "Product was successfully updated."
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
      params.require(:product).permit(:type, :cost, :thread_cost, :image)
    end
  end
end
