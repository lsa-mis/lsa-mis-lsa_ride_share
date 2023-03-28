# == Schema Information
#
# Table name: students
#
#  id                          :bigint           not null, primary key
#  uniqname                    :string
#  last_name                   :string
#  first_name                  :string
#  class_training_date         :date
#  canvas_course_complete_date :date
#  meeting_with_admin_date     :string
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mvr_status                  :string
#  program_id                  :bigint
#
class Student < ApplicationRecord
  belongs_to :program
  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :reservation
  has_rich_text :note

  validates :uniqname, uniqueness: { scope: :program, message: "is already in the program list" }
  validates_presence_of :first_name, :last_name

  def driver
    Reservation.where(driver: self)
  end

  def backup_driver
    Reservation.where(backup_driver: self)
  end

  def passenger
    Reservation.with_passengers.where(reservation_passengers: [self])
  end

  def reservations
    driver + backup_driver + passenger
  end
end
