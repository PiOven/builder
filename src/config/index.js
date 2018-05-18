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
  name: 'osUrl',
  default: 'https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2017-07-05/2017-07-05-raspbian-jessie-lite.zip',
  message: 'Operating System URL',
  validate: Validate.required
}, {
  type: 'input',
  name: 'osVerify',
  default: input => `${input.osUrl}.sha256`,
  message: 'Checksum URL'
}, {
  type: 'input',
  name: 'username',
  message: 'Username',
  validate: Validate.required
}, {
  type: 'input',
  name: 'hostname',
  message: 'Hostname',
  default: input => input.username,
  validate: Validate.required
}, {
  type: 'number',
  name: 'passwordLength',
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
  name: 'wifiSsid',
  message: 'WiFi SSID (2G recommended)',
  when: answers => answers._useWifi,
  validate: Validate.required
}, {
  type: 'input',
  name: 'wifiPass',
  message: 'WiFi Password',
  when: answers => answers._useWifi,
  validate: Validate.required
}, {
  type: 'input',
  name: 'ipAddressRangeStart',
  message: 'IP address range start',
  validate: Validate.isIp
}, {
  type: 'input',
  name: 'ipAddressRangeEnd',
  message: 'IP address range end',
  when: answers => !!answers.ipAddressRangeStart,
  validate: Validate.multi([
    Validate.isIp,
    Validate.ipGreaterThan('ipAddressRangeStart')
  ])
}, {
  type: 'list',
  name: 'dnsAddress',
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
  name: 'installDocker',
  message: 'Do you want to install Docker?',
  choices: [{
    name: 'Yes',
    value: true
  }, {
    name: 'No',
    value: false
  }]
}, {
  type: 'list',
  name: 'gpuMemory',
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
  name: 'mailgunDomain',
  message: 'MailGun domain',
  when: answers => answers._emailConfirm,
  validate: Validate.required
}, {
  type: 'input',
  name: 'mailgunApiKey',
  message: 'MailGun API key',
  when: answers => answers._emailConfirm,
  validate: Validate.required
}, {
  type: 'input',
  name: 'emailAddress',
  message: 'Email address',
  when: answers => answers._emailConfirm,
  validate: Validate.multi([
    Validate.required,
    Validate.isEmail
  ])
}];
