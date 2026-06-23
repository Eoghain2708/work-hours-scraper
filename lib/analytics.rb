require_relative "roster"
require_relative "calculator"
require "fuzzy_match"
require_relative "cache"
require "time"

module Analytics
  # @param employee - raw JSON including name and startDate (employment start)
  # @return {Hash} - hash containing lifetime information (hours )
  def self.calc_lifetime_data(employees, employee_name, date, client)
    result = {}
    result[:shifts_per_employee] = Hash.new(0)
    result[:total_wage] = 0
    result[:total_hours] = 0
    all_employee_shifts = work_history_for(employees, employee_name, date, client)
    name = all_employee_shifts[:name]
    all_employee_shifts[:shifts].each do |shift_data|
      result[:total_wage] += shift_data[:pay]
      result[:total_hours] += shift_data[:hours]
      shift_data[:people].each do |person|
        result[:shifts_per_employee][person] += 1 unless person == name
      end
    end


    sorted = result[:shifts_per_employee]
      .sort_by {|employee, shifts| -shifts }
      .to_h
    
    result[:generated_at] = Time.now
    result[:shifts_per_employee] = sorted
    result[:total_wage] = result[:total_wage].to_f.round(2)
    result[:total_hours] = result[:total_hours].round(2)
    Cache.write("lifetime/#{name}.json", JSON.pretty_generate(result))
    puts "Saved!"
    result
  end

  def self.retrieve_lifetime_data(employee_name)
    dir = Cache.dir
    p dir 
    p employee_name
    matcher = FuzzyMatch.new(Dir["#{dir}/lifetime/*"])
    match = matcher.find("#{employee_name}.json")
    p match
    json = Cache.read_from_path(match)
    return "No lifetime data saved for this employee" unless json
    data = JSON.parse(json)
    data
  end

  # get every shift of an employee and just add the shift to array
  # then go through array and call shifts by date on it
  # then create the hash out of people
  def self.work_history_for(employees, employee_name, date, client)
    employee = Roster.find_employee(employees, employee_name)
    name = employee.dig("displayName")
    age = employee.dig("age")
    return {} unless name

    start_date = Date.parse(employee.dig("startDate"))
    start_date -= ((start_date.wday - 5) % 7) unless start_date.friday?

    result = {}
    result[:name] = name
    result[:shifts] = []

    while date >= start_date
      pp date
      weekly_rota = client.get_employees(date)
      target = Roster.find_employee_no_match(weekly_rota, name)
      target["shifts"].each do |shift_date, data|
        people = []
        roster = Roster.shifts_by_date(weekly_rota, shift_date)
        target_shift_data = {}
        data.each do |d|
          target_shift_data[:date] = Date.parse(shift_date)
          target_shift_data[:shift] = d.dig("rosteredShiftText", "time12Hr")
          target_shift_data[:start] = d.dig("startTime", "orderableTime")
          target_shift_data[:finish] = d.dig("endTime", "orderableTime")
          target_shift_data[:hours] = d.dig("netDuration", "decimal")
          target_shift_data[:job_code] = d.dig("job", "id")
          target_shift_data[:age] = age
          target_shift_data[:pay] = ((Calculator.calc_hourly_wage({age: age, job_code: d.dig("job", "id")})) * d.dig("netDuration", "decimal")).to_f.round(2)
        end
        roster.each do |person|
          person[:shifts].each do |s|
            (people << person[:name] unless person[:name] == name) if Roster.overlap?(target_shift_data, s)
         end
        end
         target_shift_data[:people] = people
         result[:shifts] << target_shift_data
      end
      date -= 7
      
    end
    result
  end
end