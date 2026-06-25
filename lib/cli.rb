require_relative "shifts"
require "date"
class CLI
  # available commands
  # shifts hours me thisweek/nextweek
  # shifts hours name thisweek/nextweek
  # shifts willsee name name thisweek/nextweek
  def self.run(argv)
    command = argv.shift ## ARGV now contains remaining data 
    
   
    
    case command.downcase
    when "hours", "hrs"
      hours(argv)
    when "willsee", "wsee"
      willsee(argv)
    when "whosin", "who"
      whosin(argv)
    when "glifetime", "glife"
      glifetime(argv)
    when "lifetime", "life"
      lifetime(argv)
    when "help", "h"
      help
    when "rota", "r"
      rota(argv)
    else 
      abort "Unknown command: #{command}"
    end
    
    
    
  end

  def self.define_period(period)
    period = period.strip.downcase
    case period
    when "thisweek", "tweek"
      Dates.this_week
    when "nextweek", "nweek"
      Dates.next_week
    when "today", "tod"
      Dates.today
    when "tomorrow", "tom"
      Dates.tomorrow
    when "yesterday", "yes"
      Dates.yesterday
    when "lastweek", "lweek"
      Dates.last_week
    when "friday", "fri"
      Dates.friday
    when "saturday", "sat"
      Dates.saturday
    when "sunday", "sun"
      Dates.sunday
    when "monday", "mon"
      Dates.monday
    when "tuesday", "tue"
      Dates.tuesday
    when "wednesday", "wed"
      Dates.wednesday
    when "thursday", "thu"
      Dates.thursday

    # next week
    when "nfriday", "nfri"
      Dates.nfriday
    when "nsaturday", "nsat"
      Dates.nsaturday
    when "nsunday", "nsun"
      Dates.nsunday
    when "nmonday", "nmon"
      Dates.nmonday
    when "ntuesday", "ntue"
      Dates.ntuesday
    when "nwednesday", "nwed"
      Dates.nwednesday
    when "nthursday", "nthu"
      Dates.nthursday
    else
      Dates.parse_arg(period)
    end
  end

  def self.hours(argv)
    date = get_date(argv.pop)
    employees = get_employees(date)
    if argv[0].downcase == "me"
      shifts = Roster.shifts_for(employees, ENV["MY_NAME"])
    else
      shifts = Roster.shifts_for(employees, argv[0].downcase)
    end
    shift_data = Calculator.calc_shift_data(shifts, start_key: "startTime", end_key: "endTime")
    ShiftFormatter.format_shift_data(shift_data)
  end

  def self.willsee(argv)
    pp argv
    date = get_date(argv.pop)
    employees = get_employees(date)
    abort "Invalid format, format must be shifts willsee NAME NAME thisweek/nextweek" unless argv.size == 2
    p1 = argv[0].downcase
    p2 = argv[1].downcase
    p1_data = Calculator.calc_shift_data(Roster.shifts_for(employees, p1), start_key: "startTime", end_key: "endTime")
    p2_data = Calculator.calc_shift_data(Roster.shifts_for(employees, p2), start_key: "startTime", end_key: "endTime")
    Roster.find_shifts_in_common(employees, p1_data, p2_data)

  end

  def self.whosin(argv)
    date = get_date(argv.last)
    employees = get_employees(date)
    shifts = Roster.shifts_by_date(employees, date)
    shifts.each do |shift|
      ShiftFormatter.format_shift(shift)
    end
  end

  def self.glifetime(argv)
    date = get_date(argv.pop)
    name = argv.pop
    client = Client.new
    employees = client.get_employees(date)
    data = Analytics.calc_lifetime_data(employees, name, date, client)
    pp data
  end

  def self.lifetime(argv)
    name = argv.last
    data = Analytics.retrieve_lifetime_data(name)
    pp data
  end

  def self.rota(argv)
    date = get_date(argv.pop)
    client = Client.new
    employees = client.get_employees(date)
    data = Roster.full_roster_info(employees, date)
    Roster.generate_roster_table(data, date)
  end

  def self.help
    
  end

  private
  def self.get_date(input)
    date = define_period(input)
  rescue Date::Error
    abort "Invalid date input. Type 'shifts help' for help."
    date
  end

  def self.get_employees(date)
    client = Client.new
    employees = client.get_employees(date)
    employees
  end



   # begin
    #   date = define_period(period)
    # rescue Date::Error
    #   abort "Expected thisweek, nextweek, lastweek, today, tomorrow or a valid date YYYY-mm-dd for final argument"
    # end

    # client = Client.new
    # employees = client.get_employees(date)
end
