require "bigdecimal"

module Calculator
  HOURLY_WAGE = BigDecimal("13.11")

  # @param {Hash<Hash>} - nested HashMap of shifts gotten with the shifts_for method
  # @param {String} start_key - either "rosteredStartTime" or "startTime"
  # @param {String} end_key - either "rosteredEndTime" or "endTime"
  # @return {Hash<Hash>}
  # Takes in the raw shifts JSON of a single employee and then parses it, returning a Hash of 
  # their start time, finish time, hours for each shift, pay for each shift, total hours and total pay. Also includes a user-friendly
  # formatting of their shift hours.
  def self.calc_shift_data(shifts, start_key:, end_key:)
    total_shift_data = {}
    total_hours = 0
    total_pay = 0
    data = {} 
    shifts.each do |date, shift|
      shift.each do |info|
        start_time = info.dig(start_key, "orderableTime")
        finish_time = info.dig(end_key, "orderableTime")

        hours = info.dig("netDuration", "decimal")
        pay = (hours * HOURLY_WAGE).to_f
        next if hours == 0
        total_hours += hours
        data[date] ||= []
        data[date] << {
          start: start_time.round(2),
          finish: finish_time.round(2),
          hours: hours.round(2),
          pretty_shift: info.dig("shiftText")["time12Hr"],
          pay: pay
        }
        total_shift_data[:name] = info.dig("person", "name")
        total_shift_data[:shifts] = data
        total_pay += pay
      end
    end
    total_shift_data[:total_hours] = total_hours
    total_shift_data[:pay_before_tax] = total_pay.round(2)
    total_shift_data
  end
end
