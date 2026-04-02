class User < ApplicationRecord
  has_many :designs, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :ysws_eligible, inclusion: { in: [ true, false ] }

  enum :role, { user: 0, admin: 1, superadmin: 2 }, default: :user

  def admin?
    role == "admin" || role == "superadmin"
  end
end
