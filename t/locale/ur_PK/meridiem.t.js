require('proof')(4, function (assert) {
    var tz = require('timezone')(require('timezone/ur_PK'))

    // ur_PK meridiem upper case
    assert(tz('2000-09-03 08:05:04', '%P', 'ur_PK'), 'ص', 'ante meridiem lower case')
    assert(tz('2000-09-03 23:05:04', '%P', 'ur_PK'), 'ش', 'post meridiem lower case')

    // ur_PK meridiem lower case
    assert(tz('2000-09-03 08:05:04', '%p', 'ur_PK'), 'ص', 'ante meridiem upper case')
    assert(tz('2000-09-03 23:05:04', '%p', 'ur_PK'), 'ش', 'post meridiem upper case')
})
