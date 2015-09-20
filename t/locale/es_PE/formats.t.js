#!/usr/bin/env node
require("proof")(5, function (equal) {
  var tz = require("timezone")(require("timezone/es_PE"));
  // es_PE date representation
  equal(tz("2000-09-03", "%x", "es_PE"), "03/09/00", "date format");

  // es_PE time representation
  equal(tz("2000-09-03 08:05:04", "%X", "es_PE"), "08:05:04", "long time format morning");
  equal(tz("2000-09-03 23:05:04", "%X", "es_PE"), "23:05:04", "long time format evening");

  // es_PE date time representation
  equal(tz("2000-09-03 08:05:04", "%c", "es_PE"), "dom 03 sep 2000 08:05:04 UTC", "long date format morning");
  equal(tz("2000-09-03 23:05:04", "%c", "es_PE"), "dom 03 sep 2000 23:05:04 UTC", "long date format evening");
});
