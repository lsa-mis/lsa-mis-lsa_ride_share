class ReservationsController < ApplicationController
  before_action :auth_user
  before_action :set_reservation, only: %i[ show edit update destroy add_drivers add_passengers remove_passenger ]
  before_action :set_terms_and_units
  before_action :set_programs
  before_action :set_cars, only: %i[ new edit get_available_cars ]

  # GET /reservations or /reservations.json
  def index
    if current_user.unit_ids.count == 1
      @unit_id = current_user.unit_ids[0]
      @reservations = Reservation.where(program: Program.where(unit_id: @unit_id))
    elsif params[:unit_id].present?
      @unit_id = params[:unit_id]
      @reservations = Reservation.where(program: Program.where(unit_id: @unit_id))
    else
      @reservations = Reservation.all
    end
    authorize @reservations
  end

  # GET /reservations/1 or /reservations/1.json
  def show
    @passengers = @reservation.passengers
  end

  # GET /reservations/new
  def new
    if is_student?(current_user)
      @program = Student.find(params[:student_id]).program
      @unit_id = @program.unit_id
      @term_id = @program.term.id
      @sites = @program.sites
    elsif params[:unit_id].present?
      @unit_id = params[:unit_id]
    else
      redirect_to reservations_path, notice: "You must select a unit first."
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    else
      @day_start = Date.today
    end
    if params[:term_id].present?
      @term_id = params[:term_id]
    end
    @students = []
    if is_admin?(current_user)
      @sites = []
    end
    @number_of_seats = 1..Car.maximum(:number_of_seats)
    @reservation = Reservation.new
    @reservation.start_time = @day_start
    authorize @reservation
  end

  # GET /reservations/1/edit
  def edit
    @sites = @reservation.program.sites
    @number_of_seats = 1..Car.maximum(:number_of_seats)
    @day_start = @reservation.start_time.to_date
  end

  def get_available_cars
    if params[:unit_id].present?
      @unit_id = params[:unit_id]
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    end
    if params[:number].present?
      @cars = @cars.where("number_of_seats >= ?", params[:number])
    end
    if params[:time_start].present?
      @time_start = params[:time_start]
    end
    if params[:time_end].present?
      @time_end = params[:time_end]
    end
    if ((Time.zone.parse(params[:time_end]).to_datetime - Time.zone.parse(params[:time_start]).to_datetime) * 24 * 60).to_i > 15
      @reserv_begin = Time.zone.parse(params[:day_start] + " " + params[:time_start]).to_datetime
      @reserv_end = Time.zone.parse(params[:day_start] + " " + params[:time_end]).to_datetime
      range = @reserv_begin..@reserv_end
      @cars = available_cars(@cars, range, @unit_id)
    end
    authorize Reservation
  end

  # POST /reservations or /reservations.json
  def create
    @reservation = Reservation.new(reservation_params)
    @reservation.start_time = Time.zone.parse(params[:day_start] + " " + params[:time_start]).to_datetime
    @reservation.end_time = Time.zone.parse(params[:day_start] + " " + params[:time_end]).to_datetime
    @reservation.number_of_people_on_trip = params[:number_of_people_on_trip]
    @reservation.reserved_by = current_user.id
    authorize @reservation
    if @reservation.save
      @students = @reservation.program.students 
      redirect_to add_drivers_path(@reservation), notice: "Reservation was successfully created. Please add drivers."
    else
      if is_student?(current_user)
        @program = Student.find(params[:student_id]).program
        @unit_id = @program.unit_id
        @term_id = @program.term.id
        @sites = @program.sites
      else
        @sites = []
      end
      @students = []
      @number_of_seats = 1..Car.maximum(:number_of_seats)
      @cars = Car.data(params[:unit_id])
      @day_start = params[:day_start]
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /reservations/1 or /reservations/1.json
  def update
    if params[:reservation][:driver_id].present?
      @reservation.update(reservation_params)
      redirect_to add_passengers_path(@reservation)
      return
    end
    if params[:reservation][:student_id].present?
      @reservation.passengers << Student.find(params[:reservation][:student_id])
      @students = @reservation.program.students - @reservation.passengers
      redirect_to add_passengers_path(@reservation)
      return
    end
    if params[:reservation][:non_uofm_passengers].present?
      @reservation.update(non_uofm_passengers: params[:reservation][:non_uofm_passengers])
      redirect_to add_passengers_path(@reservation)
      return
    end
    respond_to do |format|
      if @reservation.update(reservation_params)
        format.html { redirect_to reservation_url(@reservation), notice: "Reservation was successfully updated." }
        format.json { render :show, status: :ok, location: @reservation }
      else
        @programs = Program.where(unit_id: current_user.unit)
        @students = Student.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  def add_drivers
    @drivers = @reservation.program.students.eligible_drivers
    unless is_admin?(current_user)
      driver = Student.find_by(program_id: @reservation.program_id, uniqname: current_user.uniqname)
      @reservation.update(driver_id: driver.id)
    end
  end

  def add_passengers
    @passengers = @reservation.passengers
    @students = @reservation.program.students - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
  end

  def remove_passenger
    @reservation.passengers.delete(Student.find(params[:student_id]))
    @passengers = @reservation.passengers
    @students = @reservation.program.students - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
  end


  # DELETE /reservations/1 or /reservations/1.json
  def destroy
    @reservation.destroy

    respond_to do |format|
      format.html { redirect_to reservations_url, notice: "Reservation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_reservation
      @reservation = Reservation.find(params[:id])
      authorize @reservation
    end

    def set_terms_and_units
      @terms = Term.sorted
      @units = Unit.where(id: current_user.unit_ids).order(:name)
    end

    def set_programs
      @programs = Program.where(unit_id: current_user.unit_ids)
    end

    def set_cars
      @cars = Car.data(params[:unit_id])
    end

    # Only allow a list of trusted parameters through.
    def reservation_params
      params.require(:reservation).permit(:status, :start_time, :end_time, :recurring, :driver_id, :driver_phone, :backup_driver_id, :backup_driver_phone, 
      :number_of_people_on_trip, :program_id, :site_id, :car_id, :reserved_by)
    end
end
