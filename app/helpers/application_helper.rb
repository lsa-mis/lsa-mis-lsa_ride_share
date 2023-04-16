module ApplicationHelper

  def default_config_questions
    [
      "Number of students using ride share",
      "<div>Type of car reservation&nbsp;</div><ul><li>Recurring</li><li>Sporadic</li><li>Events</li><li>Trips</li><li>Other</li></ul>",
      "Does The Course Have A $50 Lab Fee?",
      "<div>What training option would be best for your course? (~30-minutes needed)&nbsp;</div><ul><li>Whole Class In-Person (Recommended)&nbsp;</li><li>Whole Class Via Zoom (Recommended)&nbsp;</li><li>Small Groups Via Zoom&nbsp;</li><li>Individuals Sign Up Online&nbsp;</li><li>Other</li></ul>",
      "If whole class training is possible, what date would be best? (The admin will contact to coordinate time/location)"
    ]
  end

  def svg(svg)
    file_path = "app/assets/images/svg/#{svg}.svg"
    return File.read(file_path).html_safe if File.exist?(file_path)
    file_path
  end

  def show_date(field)
    field.strftime("%m/%d/%Y") unless field.blank?
  end

  def show_date_time(field)
    field.strftime("%m/%d/%Y %I:%M%p") unless field.blank?
  end

  def show_user_name_by_id(id)
    User.find(id).display_name_email
  end

  def updated_on_and_by(resource)
    return "Updated on " + resource.updated_at.strftime('%m/%d/%Y') + " by " + show_user_name_by_id(resource.updated_by)
  end

  def number_of_students(program)
    if program.number_of_students.present? && program.number_of_students > 0
      program.number_of_students
    else
      "The student list is not populated"
    end
  end

  def number_of_students_using_ride_share(program)
    if program.number_of_students_using_ride_share.present?
      program.number_of_students_using_ride_share
    else
      "Not available"
    end
  end

  def show_units(user)
    if is_super_admin?(user)
      "SuperAdmin"
    else
      Unit.where(id: current_user.unit).pluck(:name).join(' ')
    end
  end

  def unit_use_faculty_survey(unit)
    UnitPreference.where(unit_id: unit, name: "faculty_survey").present? && UnitPreference.where(unit_id: unit, name: "faculty_survey").pluck(:value).include?(true)
  end

  def is_super_admin?(user)
    user.membership.include?('lsa-was-rails-devs')
  end
  
  def render_flash_stream
    turbo_stream.update "flash", partial: "layouts/notification"
  end

  def us_states
    [
      ['Alabama', 'AL'],
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'],
      ['California', 'CA'],
      ['Colorado', 'CO'],
      ['Connecticut', 'CT'],
      ['Delaware', 'DE'],
      ['District of Columbia', 'DC'],
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'],
      ['Idaho', 'ID'],
      ['Illinois', 'IL'],
      ['Indiana', 'IN'],
      ['Iowa', 'IA'],
      ['Kansas', 'KS'],
      ['Kentucky', 'KY'],
      ['Louisiana', 'LA'],
      ['Maine', 'ME'],
      ['Maryland', 'MD'],
      ['Massachusetts', 'MA'],
      ['Michigan', 'MI'],
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'],
      ['Missouri', 'MO'],
      ['Montana', 'MT'],
      ['Nebraska', 'NE'],
      ['Nevada', 'NV'],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      ['Ohio', 'OH'],
      ['Oklahoma', 'OK'],
      ['Oregon', 'OR'],
      ['Pennsylvania', 'PA'],
      ['Puerto Rico', 'PR'],
      ['Rhode Island', 'RI'],
      ['South Carolina', 'SC'],
      ['South Dakota', 'SD'],
      ['Tennessee', 'TN'],
      ['Texas', 'TX'],
      ['Utah', 'UT'],
      ['Vermont', 'VT'],
      ['Virginia', 'VA'],
      ['Washington', 'WA'],
      ['West Virginia', 'WV'],
      ['Wisconsin', 'WI'],
      ['Wyoming', 'WY']
    ]
  end

end
