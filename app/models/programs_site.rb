# == Schema Information
#
# Table name: programs_sites
#
#  id         :bigint           not null, primary key
#  program_id :bigint           not null
#  site_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ProgramsSite < ApplicationRecord
  belongs_to :program
  belongs_to :site
end
