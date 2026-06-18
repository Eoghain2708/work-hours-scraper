# work-hours-scraper
A Ruby scraper which automatically logs in and extracts data from a reverse-engineered API (from my workplace), saving a loginToken in JSON for repeat extractions. Can call a variety of commands to extract data from the current rota and the upcoming one including total hours, wage, projected hours/wage (for the next rota in its current state). 

```
shifts hours me thisweek
shifts hours me nextweek

shifts hours Jim nextweek
```

Can also check whether any shifts will overlap with a different employee 

```
shifts willsee JohnDoe JaneDoe nextweek
```
