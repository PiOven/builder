/**
 * validation
 */


/* Node modules */
const fs = require('fs');

/* Third-party modules */
const ipToInt = require('ip-to-int');
const validateEmail = require('email-validator');
const validateIp = require('validate-ip');

/* Files */

module.exports = {
  integer: (input) => {
    const str = input.toString();

    return /^\d+$/.test(str) ? true : 'Input must be an integer';
  },

  isEmail: (input) => {
    if (!input) {
      return true;
    }

    return validateEmail.validate(input) ? true : 'Invalid email address';
  },

  isFile: input => new Promise((resolve, reject) => {
    fs.stat(input, (err, stats) => {
      if (err) {
        reject(err);
        return undefined;
      }

      return stats;
    });
  }).then((stats) => {
    if (!stats.isFile()) {
      return Promise.reject(new Error(`${input} is not a file`));
    }

    return true;
  }).catch((err) => {
    if (err.code === 'ENOENT') {
      return Promise.reject(new Error(`File ${input} does not exist`));
    }

    return Promise.reject(err);
  }),

  isGTE: target => (input) => {
    const num = Number(input);

    if (Number.isNaN(num)) {
      return 'Must be a number';
    } else if (num < target) {
      return `Must be ${target} or greater`;
    }

    return true;
  },

  isIp: (input) => {
    if (!input) {
      return true;
    }

    const isValid = validateIp(input);

    if (isValid) {
      return true;
    }

    return 'Invalid IP address';
  },

  ipGreaterThan: key => (input, values) => {
    const start = values[key];

    if (!input) {
      if (start) {
        return 'Start range is set - end range is required';
      }

      return true;
    }

    const startInt = ipToInt(start).toInt();
    const endInt = ipToInt(input).toInt();

    if (startInt >= endInt) {
      return 'End IP must be greater than start IP';
    }

    return true;
  },

  multi: rules => (input, values) => rules
    .reduce((thenable, rule) => thenable
      .then(() => rule(input, values))
      .then((isValid) => {
        if (isValid !== true) {
          return Promise.reject(isValid);
        }

        return isValid;
      }), Promise.resolve()),

  required: input => (input !== '' ? true : 'Required field'),
};
