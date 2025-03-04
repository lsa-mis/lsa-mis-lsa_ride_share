# frozen_string_literal: true

class FacultySurveyPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def surveys_index?
    return false unless is_manager?
    @user.uniqname == @record[0].uniqname || @unit_ids.include?(@record.unit_id)
  end

  def show?
    user_in_access_group?
  end

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group?
  end

  def edit?
    update?
  end

  def send_faculty_survey_email?
    user_in_access_group?
  end

  def destroy?
    user_in_access_group?
  end

end
