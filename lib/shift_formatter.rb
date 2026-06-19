require "date"

module ShiftFormatter
  # @param {Hash} shift_data - must contain keys :name, :shifts, :pay_before_tax
  def self.format_shift_data(shift_data)
    puts "-" * 40
    puts "Shifts for #{shift_data[:name]}"
    shift_data[:shifts].each do |shift, info|
      info.each do |i|
        pretty_print_shift_data(shift, i)
      end
    end
    puts "Total hours: #{shift_data[:total_hours]}"
    puts "Total pay before tax: £#{shift_data[:pay_before_tax]}"
    puts "-" * 40
  end

  # @param {Hash} shift - differs from shift data in that it only includes :name, :start_time, :end_time, :pretty_print
  # Used to print a single shift with these keys rather than full saturated data (which is used in the shifts hours command)
  # This method is used to format shifts returned from the whosin command
  def self.format_shift(shift)
    puts "-" * 20
    puts "Name: #{shift[:name]}" 
    if shift[:pretty_print].size > 1
      puts "Shifts"
      shift[:pretty_print].each_with_index do |s, i|
        puts "#{i + 1}: #{s}"
      end
    else 
      puts "Shift: #{shift[:pretty_print].first}"
    end
    
    puts "Date: #{shift[:date]}"
    puts "-" * 20
  end


  private 
  def self.pretty_print_shift_data(shift, info)
    puts "*" * 40
      puts "-" * 10
      puts "date: #{Date.parse(shift).strftime("%A %d %B %Y")}"
     info.each do |k, v|
       puts "#{k}: #{v}"
     end
  end
end