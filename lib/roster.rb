require_relative "client"
require "fuzzy_match"
require "tty-table"

module Roster
  # @param employees - the json of all employees and their shifts
  # @param {String} employee_name
  # returns the full JSON of the **employee_name**'s shifts in the current collection of **employees**
  def self.shifts_for(employees, employee_name)
    employee = find_employee(employees, employee_name)
    shifts = employee&.dig("shifts")

    return {
      shifts: shifts,
      age: employee.dig("age"),
      job_code: employee.dig("defaultJob")
    }
  end


  # @param employees
  # @param {Hash<Hash>} employee_one_shifts
  # @param {Hash<Hash>} employee_two_shifts
  # Compares the shifts contained inside **employee_one_shifts** and **employee_two_shifts** and prints out a formatted
  # version of their shifts if they have any which overlap. Returns nil if either employee does not have any shifts. Puts a string confirming
  # they will not see each other if no shifts overlap
  def self.find_shifts_in_common(employees, employee_one_shifts, employee_two_shifts)
    emp_one_name = employee_one_shifts[:name]
    emp_two_name = employee_two_shifts[:name]
    found = false
    result = []
    unless employee_one_shifts[:shifts] && employee_two_shifts[:shifts]
      return [ message: "The rota is not complete yet." ]
    end

    unless employee_one_shifts[:shifts]
      return [ message: "#{emp_one_name} has no shifts scheduled yet"]
    end

    unless employee_two_shifts[:shifts]
      return [ message: "#{emp_two_name} has no shifts scheduled yet"]
    end
    employee_one_shifts[:shifts].each do |date, emp1_day|
      emp2_day = employee_two_shifts[:shifts][date]
      next unless emp2_day
      emp1_day.each do |shift1|
        emp2_day.each do |shift2|
          if overlap?(shift1, shift2)
            found = true
            overlap = calc_overlap(shift1, shift2)
            result << { shifts: 
            { 
              date: date, 
              shift_one: shift1[:pretty_shift], shift_one_name: emp_one_name,
              shift_two: shift2[:pretty_shift], shift_two_name: emp_two_name,
              overlap: overlap
              } 
            }
          end
        end
      end
    end
    return [ message: "#{emp_one_name} and #{emp_two_name} will not see each other this week :(" ] unless found
    result
  end

  def self.calc_overlap(shift1, shift2)
    overlap_start = [shift1[:start], shift2[:start]].max
    overlap_end = [shift1[:finish], shift2[:finish]].min
    overlap_end - overlap_start
  end

  # @param employees - JSON collection of employees
  # @param {Date} date - Requested day.
  # Takes in a date object and finds the roster or projected roster for that day, then formats and returns it.
  def self.shifts_by_date(employees, date)
    result = []
    employees.each do |employee|
      shifts = employee["shifts"]
      shifts.each_with_object({}) do |(shift_date, data), hash|
        next unless shift_date == date.to_s
        parsed_date = Date.parse(shift_date)
        ## data includes shifts for the day, so |d| exists in case there are multiple shifts in one day (employee doing split shifts)
        data.each do |d|
          # startTime listed as 24 sometimes in shift data if shift data exists but no shift actually occurred. 
          next if d.dig("startTime", "orderableTime") == 24
          hash[:name] = employee["displayName"]
          hash[:orderable_date] = parsed_date
          hash[:date] = parsed_date.strftime("%A %d %B %Y")
          (hash[:shifts] ||= []) << {start: d.dig("startTime", "orderableTime"), finish: d.dig("endTime", "orderableTime"), pretty_print: d.dig("shiftText", "time12Hr")}
        end
        result << hash
      end
    end
    result.reject(&:empty?).sort_by! { |h| h[:shifts].first[:start]}
  end

  def self.find_employee_no_match(employees, employee_name)
    employees.each do |e|
      return e if e["displayName"].downcase == employee_name.downcase
    end
    return nil
  end

  # @param {Array} employees, list of employees in JSON
  # @param {String} employee_name, targeted employee
  def self.find_employee(employees, employee_name)
    matcher = FuzzyMatch.new(employees, read: "displayName")
    employee = matcher.find(employee_name)
    return nil unless employee
    employee
  end

  
  def self.overlap?(shift1, shift2)
    shift1[:start] < shift2[:finish] && shift1[:finish] > shift2[:start]
  end

  def self.generate_roster_table(roster_data, start_date)
    if roster_data.empty?
      puts "The roster for next week has not been started."
      return 
    end

    make_friday!(start_date)
    week = (0..6).map { |i| start_date + i }
    table = TTY::Table.new(header: ["Name", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thu"])
    roster_data.each do |name, days|
      day_lookup = days.to_h { |day| [day[:orderable_date], day] }
 
      row = [name]
      week.each do |day|
        shift = day_lookup[day]
        if shift
          row << shift[:shifts].map { |s| s[:pretty_print] }.join(' | ')
        else 
          row << ""
        end
      end
      table << row
      table << [""] * row.size
    end
    puts table.render(:unicode, resize: true)
  end

  def self.full_roster_info(employees, date)
    finish_date = date + 6
    result = []
    while date <= finish_date 
      data = shifts_by_date(employees, date)
      result << data
      date += 1
    end
    result.flatten!
    grouped = result.group_by { |h| h[:name]}
    grouped
  end

  private
  def self.make_friday!(start_date)
    friday = if start_date.friday?
      start_date
    else
      start_date - ((start_date.wday - 5) % 7)
    end
    friday
  end
end