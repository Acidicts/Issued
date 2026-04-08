class Product < ApplicationRecord
  self.inheritance_column = :_type_disabled

  attr_accessor :cost_gbp

  has_one_attached :image
  has_many :orders
end
