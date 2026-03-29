class User < ApplicationRecord
  validates :ysws_eligible, inclusion: { in: [ true, false ] }
end
