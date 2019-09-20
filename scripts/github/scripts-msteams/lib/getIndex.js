'use strict';

const moment = require('moment');

const pattern = /\${(.*)}/;

module.exports = function (raw) {
  const matches = raw.match(pattern);

  if (matches) {
    const formatted = moment().format(matches[1]);

    return raw.replace(pattern, formatted);
  } else {
    return raw;
  }
};
