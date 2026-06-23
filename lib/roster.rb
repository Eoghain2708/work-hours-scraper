require_relative "client"
require "fuzzy_match"
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
    if !employee_one_shifts[:shifts] || !employee_two_shifts[:shifts]
      puts "These workers will not see each other this week"
      return
    end
    if employee_two_shifts[:shifts].empty? && employee_one_shifts[:shifts].empty?
        return "This rota appears not to be done yet. Check back later."
    end
    employee_one_shifts[:shifts].each do |date, emp1_day|
      emp2_day = employee_two_shifts[:shifts][date]
      next unless emp2_day
      emp1_day.each do |shift1|
        emp2_day.each do |shift2|
          if overlap?(shift1, shift2)
            found = true
            overlap = calc_overlap(shift1, shift2)
            puts "Shift in common found! Date: #{Date.parse(date).strftime("%A %d %B %Y")}"
            puts "-" * 30
            puts "#{emp_one_name}'s shift: #{shift1[:pretty_shift]}"
            puts "#{emp_two_name}'s shift: #{shift2[:pretty_shift]}"
            puts "Overlap: #{overlap} hours"
            puts "-" * 30
          end
        end
      end
    end
    puts "#{emp_one_name} and #{emp_two_name} will not see each other this week :(" unless found
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
        ## data includes shifts for the day, so |d| exists in case there are multiple shifts in one day (employee doing split shifts)
        data.each do |d|
          # startTime listed as 24 sometimes in shift data if shift data exists but no shift actually occurred. 
          next if d.dig("startTime", "orderableTime") == 24
          hash[:name] = employee["displayName"]
          hash[:date] = Date.parse(shift_date).strftime("%A %d %B %Y")
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
end