class Notification < ApplicationRecord
  belongs_to :user

  attribute :priority, :integer
  enum :priority, {
    urgent: 0,
    middling: 1,
    info: 2
  }

  def read
    return unless current_user == self.user

    self.update(:read, true)
    self.save!
  end
end
