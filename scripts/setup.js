/**
 * setup
 */

'use strict';

/* Node modules */
const fs = require('fs');
const os = require('os');
const path = require('path');

/* Third-party modules */
const inquirer = require('inquirer');
const inquirerFilePath = require('inquirer-file-path');
const validateEmail = require('email-validator');
const validateIp = require('validate-ip');

/* Files */

inquirer.registerPrompt('filePath', inquirerFilePath);

const Validate = {
  integer: input => {
    const str = input.toString();

    return /^\d+$/.test(str) ? true : 'Input must be an integer';
  },

  isEmail: input => {
    if (!input) {
      return true;
    }

    return validateEmail.validate(input) ? true : 'Invalid email address';
  },

  isFile: input => new Promise((resolve, reject) => {
    fs.stat(input, (err, stats) => {
      if (err) {
        reject(err);
        return;
      }

      return stats;
    });
  }).then(stats => {
    if (!stats.isFile()) {
      return Promise.reject(`${input} is not a file`);
    }

    return true;
  }).catch(err => {
    if (err.code === "ENOENT") {
      return Promise.reject(`File ${input} does not exist`);
    }

    return Promise.reject(err);
  }),

  isIp: input => {
    if (!input) {
      return true;
    }

    const isValid = validateIp(input);

    if (isValid) {
      return true;
    }

    return 'Invalid IP address';
  },

  multi: rules => input => {
    return rules
      .reduce((thenable, rule) => {
        return thenable
          .then(() => rule(input))
          .then(isValid => {
            if (isValid !== true) {
              return Promise.reject(isValid);
            }

            return isValid;
          });
      }, Promise.resolve());
  },

  required: input => input !== '' ? true : 'Required field',
};

function getCurrentDrive () {
  let out = '';
  if (os.platform() === 'win32') {
    return 'C';
  }
  out += path.sep;

  return out;
}

const questions = [{
  type: 'input',
  name: 'PI_OS',
  default: 'https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2017-07-05/2017-07-05-raspbian-jessie-lite.zip',
  message: 'Operating System URL',
  validate: Validate.required,
}, {
  type: 'input',
  name: 'PI_USERNAME',
  message: 'Username',
  validate: Validate.required,
}, {
  type: 'input',
  name: 'PI_HOSTNAME',
  message: 'Hostname',
  default: input => input.PI_USERNAME,
  validate: Validate.required,
}, {
  type: 'filePath',
  name: 'PI_SSH_KEY',
  message: 'Public SSH key path',
  basePath: getCurrentDrive(),
}, {
  type: 'list',
  name: '_useWifi',
  message: 'Do you want to connect via WiFi?',
  choices: [{
    name: 'Yes',
    value: true,
  }, {
    name: 'No',
    value: false,
  }],
}, {
  type: 'input',
  name: 'PI_WIFI_SSID',
  message: 'WiFi SSID',
  when: answers => answers._useWifi,
  validate: Validate.required,
}, {
  type: 'password',
  name: 'PI_WIFI_PASS',
  message: 'WiFi Password',
  when: answers => answers._useWifi,
  validate: Validate.required,
}, {
  type: 'input',
  name: 'PI_IP_ADDRESS_RANGE_START',
  message: 'IP address range start',
  validate: Validate.isIp,
}, {
  type: 'input',
  name: 'PI_IP_ADDRESS_RANGE_END',
  message: 'IP address range end',
  validate: Validate.isIp,
}, {
  type: 'list',
  name: 'PI_INSTALL_DOCKER',
  message: 'Do you want to install Docker?',
  choices: [{
    name: 'Yes',
    value: 'true',
  }, {
    name: 'No',
    value: 'false',
  }]
}, {
  type: 'list',
  name: 'PI_GPU_MEMORY',
  message: 'Configure the GPU memory allocation',
  choices: [{
    name: 'Default',
    value: undefined,
  }, {
    value: 16,
  }, {
    value: 32,
  }, {
    value: 64,
  }, {
    value: 128,
  }, {
    value: 256,
  }],
}, {
  type: 'list',
  name: '_emailConfirm',
  message: 'Do you want to send an email when it\'s configured?',
  choices: [{
    name: 'Yes',
    value: true,
  }, {
    name: 'No',
    value: false,
  }],
}, {
  type: 'input',
  name: 'PI_MAILGUN_DOMAIN',
  message: 'MailGun domain',
  when: answers => answers._emailConfirm,
  validate: Validate.required,
}, {
  type: 'input',
  name: 'PI_MAILGUN_API_KEY',
  message: 'MailGun API key',
  when: answers => answers._emailConfirm,
  validate: Validate.required,
}, {
  type: 'input',
  name: 'PI_EMAIL_ADDRESS',
  message: 'Email address',
  when: answers => answers._emailConfirm,
  validate: Validate.multi([
    Validate.required,
    Validate.isEmail,
  ]),
}];

inquirer.prompt(questions)
  .then((answers) => {
    answers.PI_SSH_KEY = getCurrentDrive() + answers.PI_SSH_KEY;

    const settings = [
      '#!/bin/sh',
      '',
    ];

    Object
      .keys(answers)
      .filter(key => /^_/.test(key) === false)
      .filter(key => answers[key] !== undefined)
      .forEach(key => {
        settings.push(`${key}="${answers[key]}"`);
      });

    /* Add trailing line */
    settings.push('');

    const filePath = path.join(__dirname, '..', 'settings.sh');
    const data = settings.join('\n');

    fs.writeFileSync(filePath, data, 'utf8');
  });
