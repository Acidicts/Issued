# == Schema Information
#
# Table name: batches
#
#  id         :bigint           not null, primary key
#  number     :integer
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Batch < ApplicationRecord
  MAX_ORDERS = 15

  attribute :status, default: :filling
  enum :status, {
    filling: 0,
    pending: 1,
    being_fufilled: 2,
    completed: 3
  }

  has_many :orders, after_add: :transition_if_full

  def full?
    orders.count >= MAX_ORDERS
  end

  def transition_if_full(*)
    pending! if filling? && full?
  end

  alias_method :check_fullness!, :transition_if_full
end
