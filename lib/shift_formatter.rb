require "date"
require "pastel"

module ShiftFormatter
  PASTEL = Pastel.new
  # @param {Hash} shift_data - must contain keys :name, :shifts, :pay_before_tax
  def self.format_shift_data(shift_data)
    unless shift_data && shift_data[:shifts]
      puts PASTEL.bright_red.bold "No shifts rostered yet"
      return
    end
    puts "-" * 40
    puts "Shifts for #{PASTEL.cyan.bold(shift_data[:name])}"
    puts "Role: #{PASTEL.bright_yellow.bold(shift_data[:role])}"
    puts "Hourly wage: #{PASTEL.green.bold ("£#{shift_data[:hourly_wage]}")}" 
    shift_data[:shifts].each do |shift, info|
      info.each do |i|
        pretty_print_shift_data(shift, i)
      end
    end
    puts "-" * 15
    puts PASTEL.bold.bright_cyan "Total hours: #{shift_data[:total_hours]}"
    puts PASTEL.bright_green "Total pay before tax: #{PASTEL.bold.bright_green ("£#{shift_data[:pay_before_tax]}")}"
    puts "-" * 40
  end

  # @param {Hash} shift - differs from shift data in that it only includes :name, :start_time, :end_time, :pretty_print
  # Used to print a single shift with these keys rather than full saturated data (which is used in the shifts hours command)
  # This method is used to format shifts returned from the whosin command
  def self.format_shift(shift)
    return unless shift && shift[:shifts].size > 0
    puts "-" * 20
    puts "#{PASTEL.bright_green.bold "Name:"} #{PASTEL.bold shift[:name]}" 
    if shift[:shifts].size > 1
      puts PASTEL.bright_green.bold "Shifts"
      shift[:shifts].each_with_index do |s, i|
        puts "#{PASTEL.bright_green.bold i + 1}: #{PASTEL.white.bold s[:pretty_print]}"
      end
    else 
      puts "#{PASTEL.bright_green.bold "Shift:"} #{PASTEL.bold shift[:shifts].first[:pretty_print]}"
    end
    
    puts PASTEL.bright_green.bold "Date: #{PASTEL.white.bold shift[:date]}"
    puts "-" * 20
  end

  def self.format_shifts_in_common(result)
    return unless result
    not_found = result.first[:message]
    if not_found
      puts PASTEL.bright_red not_found
      return
    end
    result.each do |hash|
      shifts = hash[:shifts]
      format_shift_in_common(shifts)
    end
  end


  private 
  def self.format_shift_in_common(shifts)
    puts "#{PASTEL.green.bold "Shift in common found!"}" + " #{PASTEL.bold "Date:"} #{PASTEL.bright_red.bold Date.parse(shifts[:date]).strftime("%A %d %B %Y")}"
    puts "-" * 30
    puts "#{PASTEL.bold PASTEL.bright_cyan shifts[:shift_one_name]}: #{PASTEL.bold shifts[:shift_one]}"
    puts "#{PASTEL.bold PASTEL.bright_yellow shifts[:shift_two_name]}: #{PASTEL.bold shifts[:shift_two]}"
    puts "#{PASTEL.bold PASTEL.bright_magenta "Overlap:"} #{PASTEL.bold shifts[:overlap]} hours"
    puts "-" * 30
  end


  private 
  def self.pretty_print_shift_data(shift, info)
    puts "*" * 40
      puts "-" * 10
      puts "#{PASTEL.bright_blue "date"}: #{PASTEL.bright_magenta.bold Date.parse(shift).strftime("%A %d %B %Y")}"
     info.each do |k, v|
       puts "#{PASTEL.bright_blue k}: #{PASTEL.bright_magenta.bold v}"
     end
  end
end