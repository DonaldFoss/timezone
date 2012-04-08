#!/usr/bin/env coffee

# Used for debugging. If you don't see them called in the code, it means the
# code is absolutely bug free.
die = (splat...) ->
  console.log.apply console, splat if splat.length
  process.exit 1
say = (splat...) -> console.log.apply console, splat

# Constants for units of time in milliseconds.
SECOND  = 1000
MINUTE  = SECOND * 60
HOUR    = MINUTE * 60
DAY     = HOUR   * 24

data = require("./timezones/northamerica")

en_US =
  day:
    abbrev: "Sun Mon Tue Wed Thu Fri Sat".split /\s/
    full: """
      Sunday Monday Tuesday Wednesday Thursday Friday Saturday
    """.split /\s+/

START = 2012

##### daysInMonth(month, year)

# Return the numbers of days in the month for the given zero-indexed month in
# the given year.
daysInMonth = do ->
  DAYS_IN_MONTH = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ]

  (month, year)->
    days = DAYS_IN_MONTH[month]
    days++ if month is 1 and isLeapYear year
    days

# Parse until.
convertUntil = (entry) ->
  if not entry.stop
    if entry.until?
      fields = for field, index in ///
        ^
        (\d{4})-(\d{2})-(\d{2})
        T
        (\d{2}):(\d{2}):(\d{2})
        .000Z
        $
      ///.exec(entry.until) when index isnt 0
        parseInt(field, 10)
      fields[1]--
      entry.stop = Date.UTC.apply Date.UTC, fields
    else
      entry.stop = Number.MAX_VALUE
  entry.stop

# Convert a daylight savings time rule into miliseconds since the epoch. We
# use `Date` because it gives us the day of the week. No error checking on
# rule, it is assumed to be correct in the database. 
actualize =
  actual: (actual, year) ->
    actualize.rule actual.entry, actual.entryIndex, actual.rule, actual.ruleIndex, year
  rule: (entry, entryIndex, rule, ruleIndex, year) ->
    if ruleIndex is 1919
      say { entry, entryIndex, rule, ruleIndex, year }
      throw new Error "borked"
    # Split up the time of day.
    match = /^(\d+):(\d+)(?::(\d+))?[us]?$/.exec(rule.time).slice(1)
    [ hours, minutes, seconds ] = (parseInt number or 0, 10 for number in match)

    # Split up the daylight savings time day.
    match = ///
      ^             # start
      (?:
        (\d+)         # a fixed date
        |
        last(\w+)     # last day of month
        |
        (\w+)>=(\d+)  # day greater than or equal to date
      )
      $             # end
    ///.exec(rule.day)

    # A fixed date.
    if match[1]
      [ month, day ] = [ rule.month, parseInt(match[1], 10) ]
      date = new Date(Date.UTC(year, month, day, hours, minutes, seconds))

    # TODO On cleanup, get rid of `index`, then we don't have to underbar things
    # down below.
    #
    # Last of a particular day of the week in the month.
    else if match[2]
      for day, i in en_US.day.abbrev
        if day is match[2]
          index = i
          break
      day = daysInMonth(rule.month, year)
      loop
        date = new Date(Date.UTC(year, rule.month, day, hours, minutes, seconds))
        if date.getUTCDay() is index
          break
        day--

    # A day of the week greater than or equal to a day of the month.
    else
      min = parseInt match[4], 10
      for day, i in en_US.day.abbrev
        if day is match[3]
          index = i
          break
      day = 1
      loop
        date = new Date(Date.UTC(year, rule.month, day, hours, minutes, seconds))
        if date.getUTCDay() is index and date.getUTCDate() >= min
          break
        day++

    save = parseOffset rule.save or "0"

    offset = parseOffset(entry.offset) + save

    # Return wallclock milliseconds since the epoch.
    if /u$/.test rule.time
      # Wondering why this isn't wallclock right here? Because the clock on the
      # wall will be offset by the previous rule's savings. We're setting the
      # subsequent rule's savings. Therefore, we need 
      fields = new Date date.getTime() + offset
      posix = date.getTime()
      clock = "posix"
    else if /s$/.test rule.time
      standard = date.getTime()
      fields = new Date standard
      clock = "standard"
    else
      wallclock = date.getTime()
      fields = new Date wallclock
      clock = "wallclock"

    # Sortable only works if there are no rules on the same day.
    sortable = Date.UTC(fields.getUTCFullYear(), fields.getUTCMonth(), fields.getUTCDate())

    { clock, standard, entry, sortable, rule, wallclock, year, posix, save, ruleIndex, entryIndex, offset }
  entry: (entry, entryIndex) ->
    die entry if /u$/.test entry.until
    die entry if /s$/.test entry.until
    offset = parseOffset(entry.offset)
    wallclock = convertUntil entry
    fields = new Date wallclock
    sortable = Date.UTC(fields.getUTCFullYear(), fields.getUTCMonth(), fields.getUTCDate())
    year = fields.getUTCFullYear()
    { clock: "wallclock", entry, sortable, wallclock, year, save: 0, ruleIndex: -1, offset, entryIndex }
      
# Convert offset, read from our time zone database, or from an ISO date, into
# milliseconds so we can use it to adjust milliseconds since the epoch.
parseOffset = (pattern) ->
  match = /^(-?)(\d+)(?::(\d+))?(?::(\d+))?$/.exec(pattern).slice(1)
  match[0] += "1"
  [ sign, hours, minutes, seconds ] = (
    parseInt(number or "0", 10) for number in match
  )
  offset  = hours   * HOUR
  offset += minutes * MINUTE
  offset += seconds * SECOND
  offset *= sign
  offset

iso8601 = (date) -> new Date(date).toISOString().replace(/\..*$/, "")

pad = (value) ->
  "00#{value}".slice(-2)
  

formatOffset = (offset) ->
  increment = offset / Math.abs(offset)
  sign = if offset < 0 then "-" else ""
  offset = Math.abs(offset)
  offset -= (millis = offset % 1000)
  offset /= 1000
  offset -= (seconds = offset % 60)
  offset /= 60
  offset -= (minutes = offset % 60)
  hours = offset / 60
  format = "#{sign}#{pad hours}:#{pad(minutes)}"
  format += ":#{pad(seconds)}"
  if millis
    format += ".#{millis}"
  format

# If you did do a table, how would you probe future dates? That's a good reason
# not to do a table, don't you think?
#
# Question to answer:
#
#  * How do determine future dates. What does the last rule look like? Can it be
#    calculated quickly?
#  * Would it be faster to move backwards through the the rules?
#
# Future dates would dispose of the simplicity of generating a table.

# Maximum year for purpose of sorting rules is 50 years hence.

count = 2
isoize = (object) ->
  object.iso = {}
  object.iso.posix = iso8601(object.posix) if object.posix
  object.iso.wallclock = iso8601(object.wallclock) if object.wallclock

# Set all the clocks for the start time of the given interval using the zone
# offset of the given previous interval.
setClocks = (interval, effective) ->
  offset = parseOffset(effective.entry.offset)
  save = parseOffset(effective.rule.save)
  switch interval.clock
    when "wallclock"
      interval.posix = interval.wallclock - offset - save
      interval.standard = interval.wallclock - offset
    when "posix"
      interval.wallclock = interval.posix + offset + save
      interval.standard = interval.posix + offset
    when "standard"
      interval.posix = interval.standard - offset
      interval.wallclock = interval.standard - save
    else
      die interval

# Remember that we have pseudo-POSIX for wallclock.
shifts = (say, data, name, startYear) ->
  table = []
  # Some time well in the future, for ranges.
  future = new Date(Date.UTC(new Date().getUTCFullYear() + 50, 0, 1))
  # We use a pseudo-POSIX timestamp to represent our wallclock.
  wallclock = new Date(Date.UTC(startYear, 11, 31))
  # Fetch the zone records.
  zone = data.zones[name]
  # Our initial maximum interval date is absurdly futuristic.
  max = Number.MAX_VALUE
  # Loop through the zones records. They are ordered from the most recent to the
  # start of standard time.
  #
  # This is a **bizarro** loop. We move backwards through time so the subsequent
  # interval is the one we've just visited, while the previous interval is next
  # one we'll visit. In **bizarro** low ***forward*** mean ***previous*** and
  # ***backward*** mean ***subsequent***.
  entryIndex = 0
  while entryIndex < zone.length
    # Fetch the current entry and the previous entry.
    entry = zone[entryIndex]

    # The minimum initerval start time for a daylight savings time shift must be
    # greater than the end of the previous zone record.
    #
    # TODO What do do if the previous zone until clock is posix or standard?
    min = convertUntil zone[entryIndex + 1] or { stop: Number.MIN_VALUE }

    # We wrap this in a `do` so we can break from rule record processing to
    # proceed to the previous zone record. It returns the starting year to use
    # with the next zone record, a year that will have been moved back in time
    # past years that have already been calculated. It also returns a subsequent
    # interval, the last interval processed, which cannot be fed to the callback
    # until we obtain the previous record.
    #
    # We need the previous interval because intervals, for the most part, begin
    # at a wallclock time. That is, the time of the clock on the wall tells us
    # when the clock on the wall will be adjusted. The POSIX time to adjust the
    # clock so that it is correct for the subsequent interval must be determined by
    # applying the offset of the interval previous to it.

    #
    [ startYear, subsequent ] = do (subsequent) ->
      say "entry - startYear: %d, until: %s, subsequent: %s, rules: %s",
        startYear, entry.until or "init",
        subsequent?.entry.until or (subsequent? and "init"),
        subsequent?.index isnt -1
      # The intervals carried over from the last time we went through the loop.
      carryover = []
      # When trying to find the seam when there are rules, the thing that starts 
      # is the subsequent zone entry, but the wallclock time is the start of the
      # current zone enty.
      if subsequent
        actual = actualize.entry entry, entryIndex
        if subsequent.ruleIndex is -1
          say "subsequent without rules - %s %s",
            iso8601(subsequent.wallclock), subsequent.entry.until or "init",
        else
          say "subsequent with rules - %s %s %s %s %s",
            iso8601(subsequent.wallclock), subsequent.entry.until or "init",
            subsequent.rule.from, subsequent.rule.to, subsequent.rule.month + 1
        if entry.rules
          subsequent.wallclock = actual.wallclock
          if subsequent.index is -1 or true
            carryover.push subsequent
          else
            carryover.push subsequent, actual
        else
          # Now we have our previous year, so we can calcuate the wallclock time
          # and posix time of this transition.
          if subsequent.index isnt -1
            wallclock = actual.wallclock
            posix = wallclock - actual.offset
            say "rule - #{iso8601 wallclock} #{iso8601 posix}"
            table.push posix, wallclock, subsequent.entryIndex, subsequent.ruleIndex
            if actual.wallclock > subsequent.wallclock
              return [ startYear, actual ]
          else
            wallclock = actual.wallclock
            posix = wallclock - actual.offset
            say "rule - #{iso8601 wallclock} #{iso8601 posix}"
            table.push posix, wallclock, subsequent.entryIndex, subsequent.ruleIndex

      # If no rules, return the entry as the subsequent interval.
      if not entry.rules
        return [ startYear, actualize.entry(entry, entryIndex) ]

      # Actualize our rules for the current zone entry and year.
      #
      # TODO Yes, yes, yes. You could make this list an already sorted list by
      # sorting this in the Olson file preprocessor.
      actuals = for rule, index in data.rules[entry.rules] or []
        ruleYear = Math.min(future.getUTCFullYear(), rule.to)
        actualize.rule entry, entryIndex, rule, index, ruleYear

      # Now order them by the date they ended descending, this will make it
      # easier to probe them, as they will be in the correct order.
      actuals.sort (a, b) -> b.sortable - a.sortable

      # We've chosen a notion of sortable that only works if no two rules
      # occur on the exact same day.
      if actuals.length > 1
        for index in [1...actuals.length]
          if actuals[index].sortable is actuals[index - 1].sortable
            throw new Error "two rules occur on the same day."

      # We move a start index as we move through the years, so that ever time
      # through the while loop, we can skip rule records whose ranges begin in
      # years after the current year.
      startIndex = 0
      # Start with out start year. TODO Superfluous. Also, `loop`.
      year = startYear
      while year >= 0
        # Start with our carryover, emptying the carryover list.
        adjustments = carryover.splice(0)

        # Index into the list of intervals.
        index = startIndex

        # We gather up any rules applying to this year. We want all rules at
        # once so we can sort them and push them onto the table in order. They
        # are not garunteed to be discovered in the correct order in tables.
        # If the start of DST is constant for a longer period than the end of
        # DST, then the range the start of DST will end after an overlapping
        # range for the end of DST. Thus, we search up all of the ranges for
        # the year here, actualize them, and gather them up.
        while index < actuals.length
          rule = actuals[index].rule
          if rule.from <= year <= rule.to
            adjustments.push actualize.actual actuals[index], year
            index++
          else if year < rule.from and index is startIndex
            index = ++startIndex
          else if year > rule.to
            break
          else
            index++

        # If no adjustments have been found, then we can rewind to the last
        # year in the next range.
        if adjustments.length is 0
          actual = actuals[index]
          year = actual.rule.to if actual
          if not actual or min > actual.wallclock
            return [ year, actual ]
          continue

        # Oldest first.
        adjustments.sort (a, b) -> b.sortable - a.sortable

        # Convert our adjustments into posix and pseudo-posix wallclock.
        for actual in adjustments
          # Local namespace for the previous year.
          prev = { year }
          # Look at this year and the previous year for a shift.
          while not prev.found and prev.year isnt year - 2
            # We use `continue` to save ourselves some indents.
            for prevIndex in [startIndex...actuals.length]
              # Each rule can only apply a year once. (Obviously.)
              prev.rule = actuals[prevIndex].rule
              continue if prev.rule is actual.rule
              # Surrender if we've gone too far back in time.
              break if prev.year > prev.rule.to
              # Reject this rule if it is not in the current year.
              continue unless prev.rule.from <= prev.year <= prev.rule.to
              # Reject this rule if it preceeds the current rule.
              prev.actual = actualize.actual actuals[prevIndex], prev.year
              continue if prev.actual.sortable > actual.sortable
              prev.found = true
              # Found it.
              break
            # If we haven't found a rule this year, let's look at last year.
            prev.year-- unless prev.found

          # We did not find a rule that precedes our rule in the current year or
          # last year. That means that there are no rules that encompase the
          # previous year. We need to go back in time and find the last rule
          # applied, so that we can know what sort of savings is in effect.
          if not prev.found
            # Because we've ordered rules by their last application decsending,
            # we know that the next rule in our list of rules was the last rule
            # applied before the current rule.
            if index < actuals.length
              prev.actual = actuals[index]
              prev.rule = prev.actual.rule
              prev.year = prev.actual.rule.to
            # Ah, but if there is no next rule, it gets tricky.
            #
            # What I'm relating here is discovered through observation.
            #
            # We make our own rules!
            #
            # Rules start with the first application of some sort of savings. In
            # our ordering rules, the last rule in our list is the first
            # application of daylight savings. Prior to the application of the
            # last rule, there is no savings in effect. It is standard time.
            #
            # However, there is no rule record, so we need to fetch one. We
            # might be bold and assume that the second to last rule record is
            # standard time, but we are meek. We actually search for a rule
            # record who's savings is zero.
            else
              if actual.ruleIndex is -1
                say "before first rule - %s %s",
                  iso8601(actual.wallclock), actual.entry.until or "init"
              else
                say "before first rule - %s %s %s %s %s",
                  iso8601(actual.wallclock), actual.entry.until or "init",
                  actual.rule.from, actual.rule.to, actual.rule.month + 1
              for standard in actuals.slice(0).reverse()
                if parseOffset(standard.rule.save) is 0
                  prev.actual = actualize.actual standard, year
                  break
              prev.rule = prev.actual.rule
              prev.year = year
              # We need to set up this last record so that it gets sent to the
              # next go around as the zone in effect needing a start time. The
              # start time will be the cutting edge of the next zone entry.
              preceeding = prev.actual
          # Now we have our previous year, so we can calcuate the wallclock
          # time and posix time of this transition.
          setClocks actual, prev.actual
          # Hit the end of the previous new zone entry. We have figured out
          # the rule that will apply when the new entry begins, but we don't
          # know the wallclock time because the previous rules are not in the
          # current sent of rules.
          if min >= actual.wallclock
            say "too old - %s %s %s %s %s",
              iso8601(actual.wallclock), actual.entry.until or "init",
              actual.rule.from, actual.rule.to, actual.rule.month + 1
            return [ year, actual ]
          # There's always next year.
          year = prev.year
          # Behavior appears to differ based on whether we're dealing with a
          # rule or a zone entry. Zone entiries appear to always trump rules.
          if max is actual.wallclock and max isnt Number.MAX_VALUE and false
            say "just right? - %s %s %s %s %s",
              iso8601(actual.wallclock), actual.entry.until or "init",
              actual.rule.from, actual.rule.to, actual.rule.month + 1
            return [ year, actual ]
          if max < actual.wallclock and actual isnt subsequent
            say "too young - %s %s %s %s %s",
              iso8601(actual.wallclock), actual.entry.until or "init",
              actual.rule.from, actual.rule.to, actual.rule.month + 1
            continue
          # Huzzah! Add an entry to our table.
          say "rule - #{iso8601 actual.wallclock} #{iso8601 actual.posix}"
          table.push actual.posix, actual.wallclock, actual.entryIndex, actual.ruleIndex
        # If we had to make our own initial standard rule record, we feed that
        # to the next zone entry as the subsequent interval.
        return [ year, preceeding ] if preceeding
    # The minimum time for an interval start becomes the  maximum time for an
    # interval end.
    max = min
    # Onward to the next zone record.
    entryIndex++
  table.push Number.MIN_VALUE, Number.MIN_VALUE, zone.length - 1, -1
  for index in [0...table.length - 4] by 4
    posix = table[index]
    wallclock = table[index + 1]
    from = tableFormat(table, zone, data.rules, index + 4)
    to = tableFormat(table, zone, data.rules, index)
    console.log "#{name} #{iso8601 wallclock} #{iso8601 posix} #{from} #{to}"

tableFormat = (table, zone, rules, index) ->
  offset = formatOffset tableOffset table, zone, rules, index
  entry = zone[table[index + 2]]
  abbrev = entry.format.replace /%s/, ->
    data.rules[entry.rules][table[index + 3]].letter
  "#{offset}/#{abbrev}"

tableOffset = (table, zone, rules, index) ->
  entry = zone[table[index + 2]]
  if not entry
    die { zone, index: table[index + 2] }
  offset = parseOffset entry.offset
  ruleIndex = table[index + 3]
  if ruleIndex isnt -1
    rule = data.rules[entry.rules][ruleIndex]
    offset += parseOffset rule.save or "0"
  offset

shifts(say, data, process.argv[2], START)
