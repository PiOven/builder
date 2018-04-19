/**
 * index
 */

'use strict';

/* Node modules */

/* Third-party modules */

/* Files */
const Validate = require('./validation');

module.exports = [{
  type: 'input',
  name: 'PI_OS',
  default: 'https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2017-07-05/2017-07-05-raspbian-jessie-lite.zip',
  message: 'Operating System URL',
  validate: Validate.required
}, {
  type: 'input',
  name: 'PI_USERNAME',
  message: 'Username',
  validate: Validate.required
}, {
  type: 'input',
  name: 'PI_HOSTNAME',
  message: 'Hostname',
  default: input => input.PI_USERNAME,
  validate: Validate.required
}, {
  type: 'number',
  name: 'PI_PASSWORD_LENGTH',
  message: 'Password length',
  default: 32,
  validate: Validate.isGTE(8)
}, {
  type: 'list',
  name: '_useWifi',
  message: 'Do you want to connect via WiFi?',
  choices: [{
    name: 'Yes',
    value: true
  }, {
    name: 'No',
    value: false
  }]
}, {
  type: 'input',
  name: 'PI_WIFI_SSID',
  message: 'WiFi SSID',
  when: answers => answers._useWifi,
  validate: Validate.required
}, {
  type: 'input',
  name: 'PI_WIFI_PASS',
  message: 'WiFi Password',
  when: answers => answers._useWifi,
  validate: Validate.required
}, {
  type: 'input',
  name: 'PI_IP_ADDRESS_RANGE_START',
  message: 'IP address range start',
  validate: Validate.isIp
}, {
  type: 'input',
  name: 'PI_IP_ADDRESS_RANGE_END',
  message: 'IP address range end',
  when: answers => !!answers.PI_IP_ADDRESS_RANGE_START,
  validate: Validate.multi([
    Validate.isIp,
    Validate.ipGreaterThan('PI_IP_ADDRESS_RANGE_START')
  ])
}, {
  type: 'list',
  name: 'PI_DNS_ADDRESS',
  message: 'Which DNS server do you want to use?',
  choices: [{
    name: 'CloudFlare',
    value: '1.1.1.1 1.0.0.1'
  }, {
    name: 'Google',
    value: '8.8.8.8 8.8.4.4'
  }, {
    name: 'OpenDNS',
    value: '208.67.222.222 208.67.220.220'
  }]
}, {
  type: 'list',
  name: 'PI_INSTALL_DOCKER',
  message: 'Do you want to install Docker?',
  choices: [{
    name: 'Yes',
    value: 'true'
  }, {
    name: 'No',
    value: 'false'
  }]
}, {
  type: 'list',
  name: 'PI_GPU_MEMORY',
  message: 'Configure the GPU memory allocation',
  choices: [{
    name: 'Default',
    value: undefined
  }, {
    value: 16
  }, {
    value: 32
  }, {
    value: 64
  }, {
    value: 128
  }, {
    value: 256
  }]
}, {
  type: 'list',
  name: '_emailConfirm',
  message: 'Do you want to send an email when it\'s configured?',
  choices: [{
    name: 'Yes',
    value: true
  }, {
    name: 'No',
    value: false
  }]
}, {
  type: 'input',
  name: 'PI_MAILGUN_DOMAIN',
  message: 'MailGun domain',
  when: answers => answers._emailConfirm,
  validate: Validate.required
}, {
  type: 'input',
  name: 'PI_MAILGUN_API_KEY',
  message: 'MailGun API key',
  when: answers => answers._emailConfirm,
  validate: Validate.required
}, {
  type: 'input',
  name: 'PI_EMAIL_ADDRESS',
  message: 'Email address',
  when: answers => answers._emailConfirm,
  validate: Validate.multi([
    Validate.required,
    Validate.isEmail
  ])
}];
