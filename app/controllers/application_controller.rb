class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :set_membership
  after_action :verify_authorized, unless: :devise_controller?

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def auth_user
    unless user_signed_in?
      redirect_to root_path, notice: 'You must sign in first!'
    end
  end

  def set_membership
    if user_signed_in?
      current_user.membership = session[:user_memberships]
    else
      new_user_session_path
    end
  end

  def after_sign_in_path_for(resource)
    if session[:user_memberships].include?('lsa-rideshare-admins')
      programs_path 
    else
      root_path
    end
  end

end
