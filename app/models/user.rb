class User < ApplicationRecord
  has_many :designs, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :ysws_eligible, inclusion: { in: [ true, false ] }
end
