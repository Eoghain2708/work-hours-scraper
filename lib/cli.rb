require_relative "shifts"
require "date"
class CLI
  ALLOWED_COMMANDS = ["hours", "willsee", "whosin", "lifetime"]
  # available commands
  # shifts hours me thisweek/nextweek
  # shifts hours name thisweek/nextweek
  # shifts willsee name name thisweek/nextweek
  def self.run(argv)
    command = argv.shift ## ARGV now contains remaining data 
    abort "Invalid command" unless ALLOWED_COMMANDS.include?(command.downcase)
    period = argv.pop.downcase

    begin
      date = define_period(period)
    rescue Date::Error
      abort "Expected thisweek, nextweek, lastweek, today, tomorrow or a valid date YYYY-mm-dd for final argument"
    end

    client = Client.new
    employees = client.get_employees(date)
    
    case command
    when "hours"
      hours(employees, argv)
    when "willsee"
      willsee(employees, argv)
    when "whosin"
      whosin(employees, date)
    when "lifetime"
      lifetime(employees, argv.last, date, client)
    else 
      abort "Unknown command: #{command}"
    end
    
    
    
  end

  def self.define_period(period)
    period = period.strip.downcase
    case period
    when "thisweek"
      Dates.this_week
    when "nextweek"
      Dates.next_week
    when "today"
      Dates.today
    when "tomorrow"
      Dates.tomorrow
    when "lastweek"
      Dates.last_week
    else
      Dates.parse_arg(period)
    end
  end

  def self.hours(employees, argv)
    abort "Invalid format, should be shifts hours NAME thisweek/nextweek" unless argv.size == 1
    if argv[0].downcase == "me"
      shifts = Roster.shifts_for(employees, ENV["MY_NAME"])
    else
      shifts = Roster.shifts_for(employees, argv[0].downcase)
    end
    shift_data = Calculator.calc_shift_data(shifts, start_key: "startTime", end_key: "endTime")
    ShiftFormatter.format_shift_data(shift_data)
  end

  def self.willsee(employees, argv)
    abort "Invalid format, format must be shifts willsee NAME NAME thisweek/nextweek" unless argv.size == 2
    p1 = argv[0].downcase
    p2 = argv[1].downcase
    p1_data = Calculator.calc_shift_data(Roster.shifts_for(employees, p1), start_key: "startTime", end_key: "endTime")
    p2_data = Calculator.calc_shift_data(Roster.shifts_for(employees, p2), start_key: "startTime", end_key: "endTime")
    Roster.find_shifts_in_common(employees, p1_data, p2_data)

  end

  def self.whosin(employees, date)
    shifts = Roster.shifts_by_date(employees, date)
    pp shifts
    shifts.each do |shift|
      ShiftFormatter.format_shift(shift)
    end
  end

  def self.lifetime(employees, name, date, client)
    employee = Roster.find_employee(employees, name)
    data = Analytics.calc_lifetime_data(employees, name, date, client)
    pp data
  end
end