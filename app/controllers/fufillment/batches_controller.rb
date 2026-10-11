class Fufillment::BatchesController < Fufillment::FufillmentController
  before_action :set_batch, only: %i[show edit update]

  def index
    @batches = Batch.order(number: :asc)
  end

  def show
    @orders = @batch.orders.order(:id)
  end

  def new
    @batch = Batch.new
  end

  def edit
  end

  def create
    @batch = Batch.new(batch_params)

    if @batch.save
      redirect_to fufillment_batch_path(@batch), notice: "Batch created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @batch.update(batch_params)
      redirect_to fufillment_batch_path(@batch), notice: "Batch updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(:number, :status)
  end
end
