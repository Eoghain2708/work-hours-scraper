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
    Cache.write("#{name}.json", result)
    puts "Saved!"
    result
  end

  def self.retrieve_lifetime_data(employee_name)
    dir = Cache.dir
    matcher = FuzzeMatch.new(Dir["#{dir}/*"])
    json = Cache.read(matcher.match("#{employee_name}.json"))
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
        roster.each do |person|
          people << person[:name] unless person[:name] == name
        end
        data.each do |d|
          result[:shifts] << { 
            date: Date.parse(shift_date),
            shift: d.dig("rosteredShiftText", "time12Hr"),
            start: d.dig("startTime", "orderableTime"),
            finish: d.dig("endTime", "orderableTime"),
            hours: d.dig("netDuration", "decimal"),
            job_code: d.dig("job", "id"),
            age: age,
            people: people,
            pay: ((Calculator.calc_hourly_wage({age: age, job_code: job_code})) * d.dig("netDuration", "decimal")).to_f.round(2)
        }
        end
      end
      date -= 7
      
    end
    result
  end

  # while date > start_date
  #     employee_data = client.get_employees(date)
  #     employees = employee_data
  #     employees.each do |emp|
  #       shifts = emp["shifts"]
  #       shifts.each do |shift, data|
  #         pp Date.parse(shift)
  #         daily_rota = Roster.shifts_by_date(employee_data, Date.parse(shift))
  #         next unless daily_rota.any? { |h| h[:name] == name }
  #         daily_rota.each do |person|
  #           next if person[:name] == name
  #           result[:shifts_per_employee][person[:name]] += 1
  #         end
  #       end
  #     end
  #     shift_data = Calculator.calc_shift_data(Roster.shifts_for(employee_data, name), start_key: "startTime", end_key: "endTime")
  #     result[:total_wages] ? result[:total_wages] += shift_data[:pay_before_tax] : result[:total_wages] = shift_data[:pay_before_tax]
  #     date -= 7
  #   end
  #   pp result
end