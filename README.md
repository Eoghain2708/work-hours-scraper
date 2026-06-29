# shifts
**shifts** is a Ruby scraper which automatically logs in and extracts data from a reverse-engineered API (from my workplace), saving a loginToken in JSON for repeat extractions. It can call a variety of commands to extract data from the current rota and the upcoming one including total hours, wage, projected hours/wage (for the next rota in its current state). 

## Commands (cheat sheet)
(all prefaced by **shifts** as the exectuable)
For the date argument, WEEK or DAY refers to what the command is expecting - in both cases, a single date is passed in, for example, 2026-06-25; however, that day may be treated as a single day, or as a reference to an entire, weeklong roster period. For handiness, shorthand aliases for common weeks (e.g "thisweek", "nextweek" ) exist for commands which process data for entire weeks, or require a specific roster period to manipulate.

1. hours (alias hrs, h) - usage: ``` shifts hours NAME DATE(WEEK) ```
2. whosin (alias who, wh) - usage: ``` shifts who DATE(DAY) ```
3. willsee (alias wsee, ws) - usage: ``` shifts willsee NAME NAME DATE(WEEK) ```
4. glifetime (alias glife) - usage: ``` shifts glifetime NAME DATE(WEEK) ```
5. lifetime (alias life) - usage: ``` shifts lifetime NAME ```
6. rota (alias r) - usage: ``` shifts rota DATE(WEEK)


### hours (alias hrs, h)
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
### willsee (alias wsee, ws)
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

### whosin (alias who, wh)
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

### glifetime (alias glife)
**glifetime** takes a person's name and a specific date in which they were present on the roster. It then counts back, week by week, keeping a rolling count of specific details - for every week (roster period) the person worked there, the methods behind glifetime will track the employees with whom they had overlapping shifts, the job ID they had (to determine whether they were a general staff, supervisor, or manager, so as to calculate hourly wage), and their total hours worked per week. This returns a hash containing a list of every single employee the person ever worked with, and how many shifts they had together, and the approximate total wage of the person. When a lifetime report is generated with this command, it is cached in a JSON file in __.cache/lifetime__ with the **displayName** of that person, taken from the JSON response. FuzzyMatch is used for easy generating as usual, but the real name of the person is quickly taken from the roster and used thereafter.

```
shifts glifetime Aaron lastweek # lastweek is used for people still currently employed - as their hours for last week are confirmed and not projected
# Example output
{shifts_per_employee:
{    "Alice Brown" => 105,
     "Barry Bottleman" => 85,
     "Celestia Steel" => 64,
     "Darry Duffelbree" => 50,
     "Eric Eccles" => 25,
     "Fionnuala Fickleberry" => 12,
     "Garry Graymeister" => 5,
     "Henriette Hobble" => 2,
     "Ian Ivantine" => 1,
     "Jaques Jollygood" => 1,
     "Kerry Kettlebottom" => 1
},
total_wage: 3453.65
generated_at: 2026-06-22 12:21:06
}

Saved to: /lifetime/Aaron Bowlington.json

```

### lifetime (alias life)
**lifetime** returns the cached JSON for a person in its original format, if it exists

```
shifts lifetime Aaron
# Example output
{shifts_per_employee:
{    "Alice Brown" => 105,
     "Barry Bottleman" => 85,
     "Celestia Steel" => 64,
     ...
```
If a lifetime report is generated for a person with glifetime, it overrides the cached version.

### rota (alias r)


