# work-hours-scraper
A Ruby scraper which automatically logs in and extracts data from a reverse-engineered API (from my workplace), saving a loginToken in JSON for repeat extractions. Can call a variety of commands to extract data from the current rota and the upcoming one including total hours, wage, projected hours/wage (for the next rota in its current state). 

## Commands
There are three commands so far: hours, willsee, whosin.

### hours
**hours** shows the given shifts and total weekly pay for a specified user. Given that the rota for the workplace comes out weekly and goes from Friday-Thursday, one only needs access to two dates. The week we're currently in, or next week. This is solved in **dates.rb**
```
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
```
With this, we can simply call thisweek or nextweek with our hours command, combined with a name. With an ENV["MY_NAME"] set up, "me" can also be passed as an argument:

```
shifts hours me thisweek
shifts hours me nextweek

shifts hours Jim nextweek

# Example Output:
----------------------------------------
Shifts for Jim
****************************************
----------
date: Thursday 25 June 2026
start: 17.0
finish: 24.0
hours: 7.0
pretty_shift: 5p-CL
pay: 91.77
****************************************
----------
date: Tuesday 23 June 2026
start: 16.25
finish: 24.0
hours: 7.75
pretty_shift: 4:15p-CL
pay: 101.6
Total hours: 14.75
Total pay before tax: £193.37
----------------------------------------


```
### willsee
**willsee** takes in two names and either thisweek or nextweek and determines whether or not the two employees will have any scheduled time working together.

```
shifts willsee JohnDoe JaneDoe nextweek

# Example Output:
Shift in common found! Date: Wednesday 24 June 2026
------------------------------
John Doe's shift: 7p-CL
Jane Doe's shift: 1p-7:30p
------------------------------
Shift in common found! Date: Sunday 21 June 2026
------------------------------
John Doe's shift: 6p-CL
Jane Doe's shift: 7p-CL
------------------------------
Shift in common found! Date: Saturday 20 June 2026
------------------------------
John Doe's shift: 3p-10p
Jane Doe's shift: 6p-CL
------------------------------
```
Includes FuzzyMatch for quicker, more carefree searching: 

```
shifts willsee johnd jando nextweek
Shift in common found! Date: Wednesday 24 June 2026
------------------------------
John Doe's shift: 7p-CL
Jane Doe's shift: 1p-7:30p
...

```

### whosin
**whosin** is self-explanatory - one can pass in a date and see the complete roster for that date very quickly. Dates are passed in the YYYY-mm-dd format. Alternatively, for shorthand, the keywords "today" and "tomorrow" are permitted.
```
shifts whosin today

# Example Output

--------------------
Name: Jane Doe
Shift: 9:30a-5p
Date: Thursday 18 June 2026
--------------------
--------------------
Name: John Doe
Shift: 3p-9:30p
Date: Thursday 18 June 2026
--------------------
--------------------
Name: Mike Doe
Shift: 5:30p-CL
Date: Thursday 18 June 2026
--------------------
--------------------
Name: Sarah Doe
Shift: 6p-CL
Date: Thursday 18 June 2026
--------------------
--------------------
Name: Mary Doe
Shift: 5p-CL
Date: Thursday 18 June 2026
--------------------
```
