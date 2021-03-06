require('proof')(5, function (assert) {
    var tz = require('timezone')(require('timezone/fr_CA'))

    // fr_CA date representation
    assert(tz('2000-09-03', '%x', 'fr_CA'), '2000-09-03', 'date format')

    // fr_CA time representation
    assert(tz('2000-09-03 08:05:04', '%X', 'fr_CA'), '08:05:04', 'long time format morning')
    assert(tz('2000-09-03 23:05:04', '%X', 'fr_CA'), '23:05:04', 'long time format evening')

    // fr_CA date time representation
    assert(tz('2000-09-03 08:05:04', '%c', 'fr_CA'), 'dim 03 sep 2000 08:05:04 UTC', 'long date format morning')
    assert(tz('2000-09-03 23:05:04', '%c', 'fr_CA'), 'dim 03 sep 2000 23:05:04 UTC', 'long date format evening')
})
