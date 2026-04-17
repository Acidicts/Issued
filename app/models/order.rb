class Order < ApplicationRecord
  belongs_to :user
  belongs_to :design
  belongs_to :product

  enum :status, { pending: 0, processing: 1, production: 2, completed: 3, cancelled: 4, user_cancelled: 5 }

  def user_cancel
    return unless current_user == user && pending?

    update(status: :user_cancelled)
  end

  def cancelled?
    cancelled? || user_cancelled?
  end
end
