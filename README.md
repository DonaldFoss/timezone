# Timezone

Compact, timezone aware time and date library for JavaScript, for use in Node.js
and the browser, 

Timezone is a database friendly, timezone aware replacement for the `Date`
object that implements date parsing, date formatting, and date math.

The Timezone library uses the [Olson timezone
database](http://cs.ucla.edu/~eggert/tz/tz-link.htm), to create a database of
timezone rules, one per continent, in a compact JSON representation, so you can,
with some confidence, determine the correct local time of any place in the
world, since 1970. It replaces the `Date` object with POSIX time, milliseconds
since the epoch, for a cross-platform, internationalized, and durable
representation of a point in time.

## Why You Need a JavaScript Timezone Library

* THEME: JavaScript `Date` Does Not Work
* SPO: http://www.english-for-students.com/Subject-Object-Predicate.html

If you've worked with dates in JavaScript, you've already run up against the
limitations of the JavaScript `Date` object. You probably already know that the
JavaScript `Date` object offers no way to parse dates, or format dates, nor does
it have any way to add or subtract time from dates.

You might not be aware of that `Date` has no concept of local time. Local time
is the time out there in the real world, the time on clock on the wall, offset
by a timezone, adjusted for daylight savings time. It is the time according to
the local government.

Local time is important if your program runs in more than one timezone. If your
program runs on the public web, then it runs in more than one timezone.

If your program runs in more than one timezone and you are entrusting your
timekeeping to the JavaScript `Date` then you are doing it wrong.

The JavaScript `Date` object has a useless dribble of support for local time.
The duplicate date field functions, some named `getXyz`, other named
`getUTCXyz`, might lead you to believe that it local time support is in effect,
but it is not.

The `getUTCXyz` methods of the `Date` object give you values of the different
date components in UTC, while the `getXyz` methods give you the UTC value offset
by some **arbitrary** number of minutes.  Yes, **arbitrary**, because the
timezone offset in JavaScript `Date` is the current timezone offset of the
client computer. The of your web application should be dictated by your web
application, not by the settings of an arbitrary client computer.

Local time is more than a single arbitrary offset. Local time is entirely
political. It is defined by borders and the whims of legislatures within those
borders. They adjust for daylight savings time. Consider the muddle that is
[time in Indiana](http://en.wikipedia.org/wiki/Time_in_Indiana), and you'll see
that a timezone is in no way scientific or standardized.

If your application works with dates in the past or the future, you need to know
when and if daylight savings time adjusts, if the local government has chosen to
apply daylight savings time at all. You need to know if the local government has
decided to move to a different timezone all together, and when this timezone
change took place.

That's why we use a timezone database to determine the local time, based on user
preferences stored in our web application.

### The Ways in Which Date Is Broken

There are some common patterns that use the JavaScript `Date` object to perform
basic date operations. They are fraught with peril.

Getting the number of minutes in a timestamp as an integer value is not terribly
useful to an application developer.

If you're formatting your dates by concatenating the `Date.getXyz` methods
string, you're making a mistake.

```javascript
// The quick and easy and wrong way to format a JavaScript date.
function brokenFormatDate (date) {
  return '' + (date.getMonth() +  1) + '/' +
               date.getDate() + '/' +
               date.getFullYear();
  }
}
```

When you create a `Date` object it will offset the field values by the timezone
offset of the computer at the time of the `Date` object's creation. You cannot
reset that offset.

Even if the `Date` value came from a server in your control, this offset is in
effect when you create the date. If you are providing dates as strings, you
might build a local date with the following date parser.

```javascript
function brokenParseDate (string) {
  var parts = /(\d{2})\/\d{2}\/\d{4}/.exec(string);
  for (var i = 1; i < 4; i++) {
    parts[i] = parseInt(parts[i], 10);
  }
  parts[1]++;
  return new Date(parts[3], parts[1], parts[2]);
}
```

### Time is Not Object-Oriented

When JavaScript was born, objects were all the rage. They were going to fix
everything, for everybody, forever.

When you model a date as an object, it is quite natural to see it as the
components of a digital clock face, each aspect of a dates display is an object
property. You adjust a date by adjusting its properties. You have a method to
get the minutes property. You have one to set the minutes property.

With your best comic book guy voice, read the following: A date, you see, is a
collection of attributes, including the number of minutes of the date, and the
day in year in which the day occurred. Using getters and setters we are able to
alter the date by adjusting its various properties. Also, there is a timezone
offset, but the end user should always have their system timzeon offset  set the
correct local time given the location of their computing device.  I, for one,
keep my computer set to Ketha standard time, the timezone of Ketha Provence on
Qo'noS, the Klingon home world.

We're rarely interested in a date as a bill of materials, an object with
component properties. The number of minutes in a date as an integer is not often
useful for application programming.

We're far more interested in dates as points in time, on a timeline, in relation
to other points on the same timeline.

POSIX time, with it's integer representation of a point is time, is a model of
time that reflects the way we think of time. Whereas the JavaScript `Date`
object is an exercise in object-orientation with a contrived result.

#### Regular Expressions Are Not Object Oriented

In large part, the utility of regular expressions comes from the language we use
to define them. It is easier to think of the pattern we want to match, if we
express it as a pattern.

```javascript
if (/$[0-9a-zA-Z]/.test("$a1")) {
  alert("Matched!");
}
```

Imagine if regular expressions had received the same treatment as dates. We'd be
assembling regular expressions through object composition, maybe through a
regular expression factory, where each step of the regular expression is
expressed as a function call.

```javascript
var regexBuilder = Regex.getFactory().newBuilder();
regexBuilder.addStartAnchor();
regexBuilder.addLiteralMatch("$");
var charClassBuilder = Regex.getFactory().newCharClassBuilder();
charClassBuilder.addRange("0", "9");
charClassBuilder.addRange("a", "z");
charClassBuilder.addRange("A", "Z");
var charClass = charClassBuilder.getInstance();
var closure = Regex.getFacetor().newKleeneClosure(charClass)
regexBuilder.addClosure(closure);
regexBuilder.endAnchor();
var regex = regexBuilder.newInstance();

if (regex.test("$a1")) {
  alert("Matched!");
}
```

Fortunately, JavaScript took a different path and chose to treat regular
expressions as expressions instead of objects.

Timezone choses to treat dates as points in time instead of objects. Timezone
choses to treat dates as expressions intead of objects.

#### Object Model Falling Down

When you display the date on a page, you don't display as an exploded diagram,
as if a date were a bill of materials.

Today's date is:

 * Year &mdash; 1969
 * Month &mdash; 5 (Zero Indexed)
 * Day &mdash; 21
 * Hour &mdash; 2
 * Minute &mdash; 36
 * Seconds &mdash; 0

You display it as a string.

Today's date is: 6/21/1969.

But, the object-oriented `Date` forces us to treat a date as a bill of materials
in our code, so that we're constantly typing out exploded diagrams of our dates.

This all too common date code is as ridiculous as a regular expression factory.

```javascript
var date = new Date();
var str = "";
str += date.getYear();
str += "/";
str += date.getMonth() + 1;
str += "/"
str += date.getDate();
str += " ";
if (date.getHours() < 10) {
  str += "0";
}
str += date.getHours();
if (date.getMinutes() < 10) {
  str += "0";
}
str += date.getMinutes();
if (date.getSeconds() < 10) {
  str += "0";
}
str += date.getSeconds();

alert("The current time is: " + str);
```

The Timezone way is much easier to express and understand.

```javascript
alert("The current time is: " + tz(tz.now, "%Y/%-m/%-d %H:%M:%S"));
```

By that token, which is easier to read, the following safer date constructor.

```javascript
var moonwalk = new Date(Date.UTC(1969, 5, 21, 2, 36));
```

Or a string?

```javascript
var moonwalk = tz("1969-05-21 02:36");
```

The major benefit of POSIX time over the `Date` object is that it is sortable.
You can order POSIX time quickly, since POSIX time is simply an integer value.

The benefit of Timezone over `Date` object is that is operates on a timeline. If
what you really want to do is get the number of minutes in a particular
timestamp as an integer, Timezone will do that. But, if what you'd rather do is
know the number of hours between a given timestamp and lunch the following
Friday, Timezone will do that too.

Hmm... Actually, do I want durations? Would that return object? Would it return
an array?

Timezone gives you a way of working with dates that is more natural, like the
regular expression built ins.

If you have sworn allegiance to design patterns, and favor the date as a bag of
integers model, because it is a model, try to think of Timezone as a domain
specific language, because those words are shinny and a very serious computer
paradigms. Timezone implements the interpreter pattern, so you can express dates
in

For the most parts, applications use dates a timestamps, search for events
within date ranges, or search for events before or after a certain date. We
format dates for display, which takes timezone and locale into account. We parse
date strings given by the user or by other systems.

The getters and setters are of dubious value:

```javascript
var moonwalk = new Date(Date.UTC(1969, 5, 21, 2, 36));
moonwalk.setUTCMinutes(moonwalk.getUTCMinutes() + 60);
alert(moonwalk.getUTCHours());
```

You have to carry those minutes yourself.

## Recording

What are you going to do? Display it? It would be nicer to have a date format
specifier to display the whole date, rather than concatenating a string with
extremely verbose object method invocations to get each part, plus the `pad`
method that needs to be rewritten every time.

What are you going to do? Increment it? If you want to move forward by minutes,
you could add the minutes and then set the value again, but if the new value is
greater than 60 then, you need to carry the minutes into the next hour.

To my mind, I could imagine building regular expressions in JavaScript using
object composition. Wouldn't that be a nightmare? Dates are so common that they
deserve their own language, like regular expressions. The Timezone library
replaces the `Date` object in applications with a domain specific language, so
that they feel more natural, like strings or regular expressions.

Dates feel unnatural because dates are represented as an object, as a box of
parts, a set of cubbyholes with getters and setters for each component.

Like regular expressions, we turn on switches, so modifiers... Good old printf.
We came back around to printf. As an example.

Make a slide show and present. Use your silly examples there. Show a regular
expression, then show it being built as an object using a factory pattern. Show
an example of someone who is a slave to fashion, 80's fashion or some silly
French fashion from the big crazy hair days.

You can get the integer value using a date format and the int modifier, which
will be null if you screw up, because the format is a programmer supplied value.

## Overview

Timezone is a timezone aware date library for JavaScript that

 * formats dates using UNIX date format specifiers,
 * formats dates adjusting for timezone and daylight savings time,
 * formats dates according to a specified locale,
 * parses RFC 822 and ISO 8601 dates,
 * parses some additional common date formats,
 * parses dates adjusting for timezone and daylight savings time,
 * parses dates according to a specified locale,
 * adds and subtracts intervals in local time adjusting for daylight savings
   time and leap days.

Timezone uses POSIX time, milliseconds since the epoch represented as a
JavaScript `Number`. Timezone does not monkey patch the JavaScript `Date`
object. Timezone replaces the JavaScript `Date` object with POSIX time.

## Time Types

Timezone works with one of two types of date value,

 * POSIX time,
 * or date strings.

Timezone uses POSIX time, milliseconds since the epoch in UTC, for a universal
representation of a point in time. Timezone uses date strings to represent local
time.

The first argument to `tz` is always a date, usually POSIX time as an integer,
or else a date string.

```javascript
// Create a POSIX time integer from a timestamp.
var bicentenial = tz("1976-07-04");
eq(88927498237492734927, bicentenial);

// Now you can use the POSIX time as a date.
eq(98327943274923794329, tz(bicentenial, "+1 millisecond"));

// You can use a date string if you prefer.
eq(98327943274923794329, tz("1976-07-04", "+1 millisecond"));
```

To express dates in your source code, simply type them out as strings and pass
them to `tz`. If you're just scripting away, it's nice to be able to specify a
date by typing it out as a string.

```javascript
// The year end clearence sale ends at year's end.
if (tz(tz.now) < tz("2012-01-01")) {
  $("#screaming-banner").text("Take advantage of our Year End Clearence Sale!");
} else {
  $("#screaming-banner").remove();
}
```

You can get the current time by passing `tz.now` as the first parameter.

You can also create a date from an array. This is helpful if you've gathered
fields values by another means. Unlike the `Date` object, the first month of the
year is 1, not 0.

```javascript
eq(tz("1976-07-04"), tz([ 1976, 7, 4 ]));
eq(tz("1969-06-21 02:36"), tz([ 1969, 6, 21, 2, 36 ]));
```

If you need pass in a `Date` object, the value of `Date.getTime()` is used.

```javascript
// Note that the Date object is problematic. If you create a date using the
// Date constructor, the timezone offset is applied at creation, so it is
// aribitrary and dependent on the timezone settings of the local machine. For
// our example here, we use Date.UTC to create a Date in a convoluted way.
var moonwalk = new Date(Date.UTC(1969, 6, 21, 2, 36));

// Now we have a Date object, let's use tz to format it.
eq("6/21/69 2:36", tz(moonwalk.getTime(), "%-m/%-d/%Y %-H:%M"));
```

## Date Formatting

Any string containing a '%' is considered a date format.

```javascript
eq("07/04/1976", tz("1976-07-04", "%m/%d/%Y"));
```

The date format specifiers are UNIX date format specifiers.

There is no way to specify a format that does not contain a '%'.

```javascript
var format;
if (authenticated) {
  format = "%Y/%m/%d";
} else {
  format = "I won't give unauthenticated users the time of day.";
}
alert(tz(tz.now, format));
```

Timezone comes with a few locales. If you'd like to contribute a locale, simply
create a JSON file in the right format and open a ticket.

## Date Parsing

Timezone can parse a handful of common date formats.

RFC 2822 / RFC 822 dates.
RFC 3339 dates.
ISO 8601 dates.
Locale based slash or dot delimited dates.
Locale based time.

Date parsing and date formatting can be a two way street, but you have to make
sure the format you use is one that Timezone can parse.

Timezone cannot parse two digit years. Sort that out before you call us. If you
are reading through an old log file, you can run a regular expression to prepend
19 to the two digit years, and make sure your new log files have a full year in
them.

## Date Math

## Date Fields

Date fields are the component parts of a timestamp.

You can get a particular date field by passing in a format specifier with the
`tz.number` parameter. The `tz.number` parameter will run the format specifier
through `parseInt` and return that value.

```javascript
// Get the year as an integer.
eq(1976, tz("1976-07-04", tz.int, "%Y"));
```

If you really do need the year of a timestamp as an integer, you won't have to
go running back to JavaScript's `Date`. Plus, you're able to use this invocation
to get integer values that `Date` doesn't provide.

```javascript
// Get the day of the year.
eq(186, tz("1976-07-04", tz.int, "%j"));
```

The `tz.array` parameter causes `tz` to return the field values as an array.

```javascript
eq([ 1969, 6, 21, 2, 36, 0, 0 ], tz("1969-06-21 02:36", tz.array)).
```

## Library Initialization

## Working with POSIX Time

Timezone will return ether a POSIX time or a formatted date string if a format
specifier is given as a parameter.

Timezone is timezone aware. It uses the same timezone names found in tzdata. The
timezone support is created from the same text database used to create the
tzdata timezone files found on most UNIX systems.

Timezone uses local time for date math, but uses POSIX time for date
comparisons. POSIX time is used for comparisons so we can compare points in
time, and know that we're not comparing timestamps in different timezones.

While Timezone uses local time for date math, an application should use POSIX
time for date comparisons. POSIX time is used for comparisons so we can compare
points in time, and know that we're not comparing timestamps in different
timezones.

When creating an application with Timezone, POSIX time is used for persistent
storage and for date comparisons. We store our dates in POSIX time and convert
them to local time when we format them for presentation.

We convert all our dates to POSIX time
Times should be stored
using POSIX time, since queries against a timestamp in a database is a
comparison.

If you're using a database, and you want to use TIMESTAMP, then make sure that
your database won't trip you up by adding the timezone offset of the server.
MySQL is not timezone aware, so I set the timezone of my MySQL servers to UTC,
because MySQL always adds the host machines current timezone offset, which is
arbitrary information that is external to and not recorded anywhere within the
database. That is, if you export your MySQL database, it doesn't record what
timezone it was running in when the database was created.

Imagine a computer programmer from New York working for a week on site in San
Francisco. She remembers that she was supposed to send out the invites for her
daughter's birthday party next month. She takes a break, and uses your cool web
invite application to send invites to a hundred people, but you used JavaScript
`Date` to parse the value from the date picker, and the time was formatted
offset to the time of workstation she was assigned for the job, and a month from
now, everyone will be showing up three hours late to a birthday party for a
broken-hearted little girl.

Thus, if we want to allow the user to move appointments forward by
a number of hours on their calendar, which would be presented in their local
time, Timezone will add the hours and then adjust the time if we enter or leave
daylight savings time.

Timezone can perform date math in both POSIX time and local time. When adding or
subtracting by hours, minutes, seconds, and milliseconds, Timezone will adjust
for daylight savings time.

As an example, let's say the you're writing a calendar application for a travel
web site, so that frequent travelers can choose from fights that do not conflict
with their scheduled appointments. To use the feature, the customers sync their
calendar with the reservation system using any iCalendar compatible calendar.
Now when they search for flights, a flight that interferes with an appointment
is flagged, so the user can see what appointments need to be rescheduled to take
that flight.

If you are a New Yorker who wants to check to see if you're going to miss any
conference calls if you take a particular flight from Vilinus to San Francisco,
you need check to see if the dates in your Eastern Time calendar fit between an
Eastern Eurpoean Time departure and a Pacific Time arrival.

Obviously, this query needs to adjust these different times to a common
timezone, which is UTC for POSIX time. The application needs to display the
appointment dates, and the arrival and departure date in their with respective
time zones offsets.

These days should all be converted to a common timezone to check for conflicts,
then the various times should be presented according to the local time of the
event.

It works with the strategy of using POSIX time as the persistent representation
of a timestamp, and converting that universal time to wall clock time for
presentation.

POSIX time is the notion of the passage of time common to all POSIX compliant
UNIX systems. It is milliseconds since the epoch in UTC. This represents a
specific point in time.

The milliseconds since the epoch in UTC value is an absolute value that is not
affected by the politics of timezones and daylight savings time. It is
considered a stable representation of a point in time, that is suitable for
storage in a database.

Strings are used to represent wall clock time. If a time needs to be presented
to a user,

You can use the `tz` function to create a date format for display, one that
cannot be in turn parsed by the `tz` function. That's fine.

## Usage

Timezone exports a single function to keep from polluting the namespace of the
client application. This single method accepts parameters similar to UNIX date.

The first parameter is always a date, either as milliseconds since the epoch as
UTC or a date string to parse.

Other arguments can appear in any order.

 * *timezone* &mdash; A timezone offset to use when parsing or formatting such
   as `EDT` or `America/Detroit`.
 * *locale* &mdash; A locale to use when parsing or formatting such as `en_US`
   or `zh_CN`.
 * *format* &mdash; A UNIX date format specifier such as `%Y/%d/%m` to return
   the date as a formatted date string, or else a switch to indicate a  canned
   format specifier like `--rfc822` or `--rfc-3339=ns`.
 * *offsets* &mdash; A set of offsets to apply to the date like `+1 day -43 minutes`.

You can pass these in any order after the initial date parameter, the `tz`
function knows what you mean.

Only one *timezone*, *locale* or *format* can be applied to a date, so if a
value is repeated for one of these parameter types, the first value is used,
subsequent values are ignored.

The *offsets* parameter can be specified multiple times. The offsets are applied
to the date in the order in which they are passed to the `tz` function.

The return value is always either milliseconds since the epoch as UTC or a date
string if the `tz` function was passed a format specifier.

## Rationale

Elsewhere, I've gone into detail on why you should not use the JavaScript `Date`
object, and why it is not even worth it to monkey patch the `Date` object to add
the missing functionality. Read JavaScript The Good Parts, and then write like
that. Don't apologize too much. In fact, you know you're going to get people who
don't understand. Google is not going to be a good referral engine, but links
from other blogs will be.

Timezone was designed to provide all of the date functionality missing from
JavaScript in a single function, to keep from polluting the namespace.

Timezone models time as a point in time on a timeline. When you need to display
time, you use the `tz` function to format the date. When you need to move
relative to a point on the timeline, you use the `tz` function to do date math
according to the rules of a local timezone. If you don't want to apply local
timezone rules, then use UTC as the local timezone.  If you want to store time
as a time as local time, store it as a string, but it can be easily compared, if
you use the ISO 8601 format, but it will get confused when you hit daylight
savings time. Much better to store as POSIX time.

When you load timezone and locale data, it is global to the application. This is
because timezone and locale data is, literally, global data. There shouldn't be
a need for two different definitions of 'de_DE' within your application. There
had better not be two different definitions of 'America/New York' in your
application.

The API is really a domain specific language. The parameters can be passed in
any order because the different parameter types have an unambiguous meaning.

The `Date` object takes POSIX time and exposes the component values, which is
somewhat useful, but not not often what you need. You don't really don't often
need the number seconds in a timestamp as an integer value, you need to parse,
format, offset and compare dates. The POSIX time representation is perfect for
comparison. Formatting is easiest to express with a format pattern.

Even if it were timezone aware, the `Date` object is not a particularly useful
representation of

## Date Math

If we land on a time missing due to the start daylight savings time, we
continue in the direction we were going, adding an additional day if we are
doing addition, subtracting an additional day if we are doing subtraction. We
then go back by 24 hours. This gives us the same counter intuitive times as
Java's Calendar.

## Just In Time Time

Always adjust your dates just in time. Store your dates in UTC. Convert them
when they are displayed. Record events using UTC on the server, not the client.
You cannot trust the client time, you do not know if the clock is set correctly,
you can't keep the user from adjusting it, even you try to account for skew.

UTC timestamps will always indicate a particular second since the epoch.


If you are doing math in hours, minutes, seconds or milliseconds, this will
reflect the UTC time.

If you are day math, you may land on a daylight savings time shift. If this is
the case, then the last day is treated as 24 hours. Otherwise, if are on a day
at 6:00 PM standard time, and go back six months to the same day, different
month, in daylight savings time, the time will still be 6:00 PM. (Use real
Detroit, Michigan examples.)

@ tz

The namespace.

~ tz(date, offset..., zone, locale)

One function to rule them all and in the darkness bind them.

# Objectives

Development tasks:

 * Parse Olson file.
 * Create searchable structure for offsets and rules.
 * Create Olson file compiler utility.
 * Create tests with controls generated by a mature timezone library such as
   CPAN's DateTime::TimeZone or UNIX `date`.
 * Create a timezone conversion method.
 * Create a date offset method.
 * Create French and German locales to seed the locale set.

Decisions:

 * Olson files are compiled into JSON, loaded as JSON.
 * On the browser side, it is the job of the client to initialize the timezone
   data, to load it and whatnot.
 * In Node.js, timezone data is loaded *synchonously* as needed, or at startup.
 * Make a magic function that does format, parse and date math based on
   parameter order, to simplify import and minimize burden on namespace.

# Swipe

Applications are going to use dates the way people use dates in the real world.
They are not a collection of attributes, but a point on a timeline, interesting
only relative to other points on that timeline.

Objects were all the rage, it is a wonder that we didn't have a regular
expression factory pattern, and build regular expressions using getters and
setters, instead of parsing regular expression patterns. That is what the date
object is like.