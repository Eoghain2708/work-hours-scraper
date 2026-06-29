require "bigdecimal"
require "dotenv"
require "date"
require "net/http"

module Calculator
  HOURLY_WAGE_UNDER_21 = BigDecimal("10.85")
  HOURLY_WAGE_21_OVER = BigDecimal("12.71")
  MANAGEMENT_BONUS = BigDecimal("0.40")

  JOB_CODES = {
    "General Manager" => "1489343527823711206",
    "Duty Manager" => "1489343542827589598",
    "Supervisor" => "1489339758941806044",
    "General Staff" => "1537027076506875352"
  }

  # @param {Hash<Hash>} - nested HashMap of shifts gotten with the shifts_for method
  # @param {String} start_key - either "rosteredStartTime" or "startTime"
  # @param {String} end_key - either "rosteredEndTime" or "endTime"
  # @return {Hash<Hash>}
  # Takes in the raw shifts JSON of a single employee and then parses it, returning a Hash of 
  # their start time, finish time, hours for each shift, pay for each shift, total hours and total pay. Also includes a user-friendly
  # formatting of their shift hours.
  def self.calc_shift_data(employee_data, start_key:, end_key:)
    total_shift_data = {}
    total_hours = 0
    total_pay = 0
    data = {} 
    hourly_wage = calc_hourly_wage(employee_data)
    employee_data[:shifts].each do |date, shift|
      shift.each do |info|
        start_time = info.dig(start_key, "orderableTime")
        finish_time = info.dig(end_key, "orderableTime")
        hours = info.dig("netDuration", "decimal")
        pay = (hours * hourly_wage).to_f.round(2)
        next if hours == 0
        total_hours += hours
        data[date] ||= []
        data[date] << {
          start: start_time.round(2),
          finish: finish_time.round(2),
          hours: hours.round(2),
          pretty_shift: info.dig("shiftText")["time12Hr"],
          pay: pay.round(2)
        }
        total_shift_data[:name] = info.dig("person", "name")
        total_shift_data[:role] = role(employee_data[:job_code])
        total_shift_data[:hourly_wage] = hourly_wage.to_f.round(2)
        total_shift_data[:shifts] = data
        total_pay += pay
      end
    end
    total_shift_data[:total_hours] = total_hours
    total_shift_data[:pay_before_tax] = total_pay.round(2)
    total_shift_data[:pay_before_tax] = total_pay.round(2)
    total_shift_data
  end

  def self.base_hourly_wage(age)
    # we don't hire < 18
    return HOURLY_WAGE_UNDER_21 if age < 21
    return HOURLY_WAGE_21_OVER
  end

  def self.calc_extra_pay_for_managers(job_code)
    return 0 if job_code == JOB_CODES["General Staff"]
    return MANAGEMENT_BONUS
  end

  def self.role(job_code)
    return "Not found" unless job_code
    JOB_CODES.each do |k, v|
      return k if v == job_code
    end
    return "General Staff"
  end

  
  def self.calc_hourly_wage(employee_data)
    return HOURLY_WAGE_UNDER_21 unless employee_data[:age] && employee_data[:job_code]
    base_hourly_wage(employee_data[:age]) + calc_extra_pay_for_managers(employee_data[:job_code])
  end
end