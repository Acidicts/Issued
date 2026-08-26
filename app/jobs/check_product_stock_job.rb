class CheckProductStockJob < ApplicationJob
  queue_as :default

  def perform
    Product.find_each do |product|
      product.check_stock
    rescue PrintfulService::Error => e
      Rails.logger.error("CheckProductStockJob: Product##{product.id} (printful #{product.printful_id}): #{e.message}")
    end
  end
end
