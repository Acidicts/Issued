class Notification < ApplicationRecord
  belongs_to :user

  attribute :priority, :integer
  enum :priority, {
    urgent: 0,
    middling: 1,
    info: 2,
    review: 3,
    system: 4,
    standard: 5
  }

  def read
    update!(read: true)
  end
end
