require_relative "client"
require "fuzzy_match"
module Roster
  # @param employees - the json of all employees and their shifts
  # @param {String} employee_name
  # returns the full JSON of the **employee_name**'s shifts in the current collection of **employees**
  def self.shifts_for(employees, employee_name)
    employee = find_employee(employees, employee_name)
    shifts = employee&.dig("shifts")
    shifts
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
    employee_one_shifts[:shifts].each do |k, v|
      next unless employee_two_shifts[:shifts].keys.include?(k)
      if employee_two_shifts[:shifts].keys.size == 0 && employee_one_shifts[:shifts].keys.size == 0
        return "This rota appears not to be done yet. Check back later."
      end
      found = true
      e2_shift = employee_two_shifts[:shifts][k]
      if e2_shift[:finish] > v[:start] || e2_shift[:start] < v[:finish]
        puts "Shift in common found! Date: #{Date.parse(k).strftime("%A %d %B %Y")}"
        puts "-" * 30
        puts "#{emp_one_name}'s shift: #{v[:pretty_shift]}"
        puts "#{emp_two_name}'s shift: #{e2_shift[:pretty_shift]}"
        puts "-" * 30
      end
    end
    puts "#{emp_one_name} and #{emp_two_name} will not see each other this week :(" unless found
  end

  # @param employees - JSON collection of employees
  # @param {Date} date - Requested day.
  # Takes in a date object and finds the roster or projected roster for that day, then formats and returns it.
  def self.shifts_by_date(employees, date)
    result = []
    employees.each do |employee|
      shifts = shifts_for(employees, employee["displayName"])
      shifts.each_with_object({}) do |(shift_date, data), hash|
        next unless shift_date == date.to_s
        data = data[0]

        # startTime listed as 24 sometimes in shift data if shift data exists but no shift actually occurred. 
        next if data.dig("startTime", "orderableTime") == 24
        hash[:name] = employee["displayName"]
        hash[:date] = Date.parse(shift_date).strftime("%A %d %B %Y")
        hash[:start_time] = data.dig("startTime", "orderableTime")
        hash[:end_time] = data.dig("endTime", "orderableTime")
        hash[:pretty_print] = data.dig("shiftText", "time12Hr")
        result << hash
      end
    end
    result
  end

 

  private

  # @param {Array} employees, list of employees in JSON
  # @param {String} employee_name, targeted employee
  def self.find_employee(employees, employee_name)
    matcher = FuzzyMatch.new(employees, read: "displayName")
    employee = matcher.find(employee_name)
    return nil unless employee
    employee
  end

  
end