require('proof')(24, function (assert) {
    var tz = require('timezone')(require('timezone/uk_UA'))

    // uk_UA abbreviated months
    assert(tz('2000-01-01', '%b', 'uk_UA'), 'січ', 'Jan')
    assert(tz('2000-02-01', '%b', 'uk_UA'), 'лют', 'Feb')
    assert(tz('2000-03-01', '%b', 'uk_UA'), 'бер', 'Mar')
    assert(tz('2000-04-01', '%b', 'uk_UA'), 'кві', 'Apr')
    assert(tz('2000-05-01', '%b', 'uk_UA'), 'тра', 'May')
    assert(tz('2000-06-01', '%b', 'uk_UA'), 'чер', 'Jun')
    assert(tz('2000-07-01', '%b', 'uk_UA'), 'лип', 'Jul')
    assert(tz('2000-08-01', '%b', 'uk_UA'), 'сер', 'Aug')
    assert(tz('2000-09-01', '%b', 'uk_UA'), 'вер', 'Sep')
    assert(tz('2000-10-01', '%b', 'uk_UA'), 'жов', 'Oct')
    assert(tz('2000-11-01', '%b', 'uk_UA'), 'лис', 'Nov')
    assert(tz('2000-12-01', '%b', 'uk_UA'), 'гру', 'Dec')

    // ' + name + ' months
    assert(tz('2000-01-01', '%B', 'uk_UA'), 'січень', 'January')
    assert(tz('2000-02-01', '%B', 'uk_UA'), 'лютий', 'February')
    assert(tz('2000-03-01', '%B', 'uk_UA'), 'березень', 'March')
    assert(tz('2000-04-01', '%B', 'uk_UA'), 'квітень', 'April')
    assert(tz('2000-05-01', '%B', 'uk_UA'), 'травень', 'May')
    assert(tz('2000-06-01', '%B', 'uk_UA'), 'червень', 'June')
    assert(tz('2000-07-01', '%B', 'uk_UA'), 'липень', 'July')
    assert(tz('2000-08-01', '%B', 'uk_UA'), 'серпень', 'August')
    assert(tz('2000-09-01', '%B', 'uk_UA'), 'вересень', 'September')
    assert(tz('2000-10-01', '%B', 'uk_UA'), 'жовтень', 'October')
    assert(tz('2000-11-01', '%B', 'uk_UA'), 'листопад', 'November')
    assert(tz('2000-12-01', '%B', 'uk_UA'), 'грудень', 'December')
})
