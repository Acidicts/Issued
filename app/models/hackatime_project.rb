# == Schema Information
#
# Table name: hackatime_projects
#
#  id         :bigint           not null, primary key
#  name       :string
#  time       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  design_id  :bigint           not null
#
# Indexes
#
#  index_hackatime_projects_on_design_id  (design_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#
class HackatimeProject < ApplicationRecord
  belongs_to :design

  def sync_hackatime_project
      project = HackatimeService.new(slack_id: self.design.user.slack_id).get_project(project_name: self.name)
      self.time = project["seconds"] if project
  end
end
