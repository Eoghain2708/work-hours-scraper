require "date"
module Dates
  def self.this_week
    today = Date.today

    friday = if today.friday?
      today
    else
      today - ((today.wday - 5) % 7)
    end
    friday
  end

  def self.next_week
    this_week + 7
  end
  
  def self.last_week
    this_week - 7
  end

  def self.today
    Date.today
  end

  def self.tomorrow
    Date.today + 1
  end

  def self.parse_arg(date_string)
    Date.parse(date_string)
  end
end