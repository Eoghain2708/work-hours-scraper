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

  def self.yesterday
    Date.today - 1
  end

  def self.friday
    this_week
  end

  def self.saturday
    this_week + 1
  end

  def self.sunday
    this_week + 2
  end

  def self.monday
    this_week + 3
  end

  def self.tuesday
    this_week + 4
  end

  def self.wednesday
    this_week + 5
  end

  def self.thursday
    this_week + 6
  end

  def self.nfriday
    next_week
  end

  def self.nsaturday
    next_week + 1
  end

  def self.nsunday
    next_week + 2
  end

  def self.nmonday
    next_week + 3
  end

  def self.ntuesday
    next_week + 4
  end

  def self.nwednesday
    next_week + 5
  end

  def self.nthursday
    next_week + 6
  end

  def self.parse_arg(date_string)
    Date.parse(date_string)
  end
end