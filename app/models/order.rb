class Order < ApplicationRecord
  belongs_to :user
  belongs_to :design
  belongs_to :product

  enum :status, { pending: 0, processing: 1, production: 2, completed: 3, cancelled: 4 }
end
