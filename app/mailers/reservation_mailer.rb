class ReservationMailer < ApplicationMailer
  before_action :set_reservation, only: [:car_reservation_created, :car_reservation_approved, :car_reservation_confirmation, :car_reservation_updated, :car_reservation_remove_passenger, :car_reservation_update_passengers]
  before_action :set_driver_name, only: [:car_reservation_created, :car_reservation_approved, :car_reservation_confirmation, :car_reservation_updated, :car_reservation_remove_passenger, :car_reservation_update_passengers]
  before_action :set_passengers, only: [:car_reservation_created, :car_reservation_approved, :car_reservation_confirmation, :car_reservation_updated, :car_reservation_remove_passenger, :car_reservation_update_passengers]

  def car_reservation_created(user, recurring = false)
    @recipient = @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    if recurring
      subject =  "New Recurring Reservation for program: #{@reservation.program.display_name_with_title}"
      email_type = "recurring_created"
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
    else
      subject = "New reservation for program: #{@reservation.program.display_name_with_title}"
      email_type = "created"
    end
    mail(to: @recipient, subject: subject)
    create_email_log_records("Reservation", @reservation, recurring, email_type, @recipient, user.id)
  end

  def car_reservation_confirmation(user, recurring = false)
    recipients = []
    recipients << User.find(@reservation.reserved_by).principal_name.presence
    recipients << email_address(@reservation.driver) if @reservation.driver.present?
    recipients << email_address(@reservation.driver_manager) if @reservation.driver_manager.present?
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    @recipients = recipients.uniq.join(", ")
    if recurring
      subject =  "Recurring Reservation confirmation for program: #{@reservation.program.display_name_with_title}"
      email_type = "recurring_confirmation"
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
    else
      subject = "New reservation confirmation for program: #{@reservation.program.display_name_with_title}"
      email_type = "confirmation"
      all_reservations = Array(@reservation.id)
    end
    mail(to: @recipients, subject: subject)
    create_email_log_records("Reservation", @reservation, recurring, email_type, @recipients, user.id)
  end

  def car_reservation_approved(user)
    recipients = []
    recipients << email_address(@reservation.driver) if @reservation.driver.present?
    recipients << email_address(@reservation.driver_manager) if @reservation.driver_manager.present?
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    @recipients = recipients.join(", ")
    @unit_email_message = get_unit_email_message(@reservation)
    mail(to: @recipients, subject: "Reservation approved for program: #{@reservation.program.display_name}" )
    EmailLog.create(sent_from_model: "Reservation", record_id: @reservation.id, email_type: "approved",
      sent_to: @recipients, sent_by: user.id, sent_at: DateTime.now)
  end

  def car_reservation_cancel_admin(cancel_reservation, cancel_passengers, cancel_emails, user, recurring = false, cancel_message = "")
    @reservation = cancel_reservation
    set_reservation_data(@reservation)
    set_driver_name
    @passengers = cancel_passengers
    if recurring
      subject = "Recurring Reservations canceled for program: #{@reservation.program.display_name_with_title}"
      email_type = "recurring_cancel_admin"
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
      @cancel_message = cancel_message + " scheduled '" + @recurring_rule + "' were canceled."
    else
      subject = "Reservation canceled for program: #{@reservation.program.display_name_with_title}"
      email_type = "cancel_admin"
      @cancel_message = "The reservation was canceled."
    end
    mail(to: @unit_email, subject: subject)
    create_email_log_records("Reservation", @reservation, recurring, email_type, @unit_email, user.id)
  end

  def car_reservation_cancel_driver(cancel_reservation, cancel_passengers, cancel_emails, user, recurring = false, cancel_message = "")
    @reservation = cancel_reservation
    set_reservation_data(@reservation)
    set_driver_name
    @passengers = cancel_passengers
    recipients = []
    recipients << User.find(@reservation.reserved_by).principal_name.presence
    recipients << email_address(cancel_reservation.driver) if cancel_reservation.driver.present?
    recipients << email_address(cancel_reservation.driver_manager) if cancel_reservation.driver_manager.present?
    recipients << email_address(cancel_reservation.backup_driver) if cancel_reservation.backup_driver.present?
    recipients << cancel_emails if cancel_emails.present?
    @recipients = recipients.join(", ")
    if recurring
      subject =  "Recurring Reservations canceled for program: #{@reservation.program.display_name_with_title}"
      email_type = "recurring_cancel_driver"
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
      @cancel_message = cancel_message + " scheduled '" + @recurring_rule + "' were canceled."
    else
      subject = "Reservation canceled for program: #{@reservation.program.display_name_with_title}"
      email_type = "cancel_driver"
      @cancel_message = "Your reservation was canceled."
    end
    mail(to: @recipients, subject: subject )
    create_email_log_records("Reservation", @reservation, recurring, email_type, @recipients, user.id)
  end

  def car_reservation_updated(user, recurring = false)
    recipients = []
    recipients << User.find(@reservation.reserved_by).principal_name.presence
    recipients << email_address(@reservation.driver) if @reservation.driver.present?
    recipients << email_address(@reservation.driver_manager) if @reservation.driver_manager.present?
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    @recipients = recipients.uniq.join(", ")
    if recurring
      subject =  "Recurring Reservations updated for program: #{@reservation.program.display_name_with_title}"
      email_type = "recurring_updated"
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
    else
      subject = "Reservation updated for program: #{@reservation.program.display_name_with_title}"
      email_type = "updated"
    end
    mail(to: @recipients, subject: subject)
    create_email_log_records("Reservation", @reservation, recurring, email_type, @recipients, user.id)
  end

  def car_reservation_drivers_edited(drivers_reservation, drivers_emails, user, recurring = false)
    @reservation = drivers_reservation
    @unit_email_message = get_unit_email_message(@reservation)
    set_reservation_data(@reservation)
    recipients = drivers_emails
    recipients << User.find(@reservation.reserved_by).principal_name.presence
    set_passengers
    set_driver_name
    recipients << @passengers_emails if @passengers_emails.present?
    recipients << @unit_email
    @recipients = recipients.uniq.join(", ")
    if recurring
      subject =  "Recurring Reservations - drivers changed for program: #{@reservation.program.display_name_with_title}"
      email_type = "recurring_drivers_edited"
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
    else
      subject = "Reservation drivers changed for program: #{@reservation.program.display_name_with_title}"
      email_type = "drivers_edited"
    end
    mail(to: @recipients, subject: subject)
    create_email_log_records("Reservation", @reservation, recurring, email_type, @recipients, user.id)
  end

  def car_reservation_remove_passenger(passenger, user, recurring = false)
    @name = passenger.name
    @email = email_address(passenger)
    if recurring
      subject =  "Recurring Reservations - removed from the reservation passagers' list for program: #{@reservation.program.display_name_with_title}"
      email_type = "recurring_passenger_removed"
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
    else
      subject = "Removed from the reservation passagers' list for program: #{@reservation.program.display_name_with_title}"
      email_type = "passenger_removed"
    end
    mail(to: @email, subject: subject )
    create_email_log_records("Reservation", @reservation, recurring, email_type, @email, user.id)
  end

  def car_reservation_update_passengers(user, recurring = false)
    recipients = []
    recipients << User.find(@reservation.reserved_by).principal_name.presence
    recipients << email_address(@reservation.driver) if @reservation.driver.present?
    recipients << email_address(@reservation.driver_manager) if @reservation.driver_manager.present?
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    recipients << @unit_email
    @recipients = recipients.uniq.join(", ")
    if recurring
      subject =  "Recurring Reservations - passengers list updated for program: #{@reservation.program.display_name_with_title}"
      email_type = "recurring_passengers_edited"
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
    else
      subject = "Reservation passengers list updated for program: #{@reservation.program.display_name_with_title}"
      email_type = "passengers_edited"
    end
    mail(to: @recipients, subject: subject)
    create_email_log_records("Reservation", @reservation, recurring, email_type, @recipients, user.id)
  end

  private 

  def set_reservation
    @reservation = params[:reservation]
    @start_time = show_date_time(@reservation.start_time)
    @end_time = show_date_time(@reservation.end_time)
    @contact_phone = @reservation.program.unit.unit_preferences.find_by(name: "contact_phone").value.presence || ""
    @unit_email = @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
  end

  def set_reservation_data(reservation)
    @start_time = show_date_time(reservation.start_time)
    @end_time = show_date_time(reservation.end_time)
    @contact_phone = reservation.program.unit.unit_preferences.find_by(name: "contact_phone").value.presence || ""
    @unit_email = reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
  end

  def set_driver_name
    if @reservation.driver.present? || @reservation.driver_manager.present?
      @driver_name = show_driver(@reservation)
    else
      @driver_name = "Not Selected"
    end
    if @reservation.backup_driver.present?
      @backup_driver_name = show_backup_driver(@reservation)
    else
      @backup_driver_name = "Not Selected"
    end
  end

  def set_passengers
    @passengers = []
    @passengers_emails =[]
    if @reservation.passengers.present? || @reservation.passengers_managers.present?
      @reservation.passengers.each do |p|
        @passengers << p.name
        @passengers_emails << email_address(p)
      end
      @reservation.passengers_managers.each do |p|
        @passengers << p.name + show_manager(@reservation.program, p.uniqname)
        @passengers_emails << email_address(p)
      end
    else
      @passengers = ["No passengers"]
    end
    if @reservation.program.non_uofm_passengers && @reservation.non_uofm_passengers.present? 
      @non_uofm_passengers = @reservation.non_uofm_passengers
    end
  end

  def get_unit_email_message(reservation)
    if UnitPreference.find_by(name: "unit_email_message", unit_id: reservation.program.unit_id).present?
      unit_email_message = UnitPreference.find_by(name: "unit_email_message", unit_id: reservation.program.unit_id).value
    else
      unit_email_message = ""
    end
    return unit_email_message
  end

  def create_email_log_records(model, reservation, recurring, email_type, recipients, user_id)
    if recurring
      all_reservations = @recurring_reservation.get_all_reservations
    else
      all_reservations = Array(reservation.id)
    end
    all_reservations.each do |id|
      EmailLog.create(sent_from_model: model, record_id: id, email_type: email_type,
        sent_to: recipients, sent_by: user_id, sent_at: DateTime.now)
    end
  end

end
