# == Schema Information
#
# Table name: ships
#
#  id              :bigint           not null, primary key
#  body            :text
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  ship_request_id :bigint           not null
#
# Indexes
#
#  index_ships_on_ship_request_id  (ship_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (ship_request_id => ship_requests.id)
#
class Ship < ApplicationRecord
  belongs_to :ship_request

  has_one :balance_event, as: :balanceable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
end
