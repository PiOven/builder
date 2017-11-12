/**
 * setup
 */

/* Node modules */
const fs = require('fs');
const os = require('os');

/* Third-party modules */
const inquirer = require('inquirer');

/* Files */

const Validate = {
  integer: input => {
    const str = input.toString();

    return /^\d+$/.test(str) ? true : 'Input must be an integer';
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

  multi: rules => input => {
    return rules
      .reduce((thenable, rule) => {
        return thenable
          .then(() => rule(input))
          .then(isValid => {
            console.log({
              isValid
            });
            if (isValid !== true) {
              return Promise.reject(isValid);
            }

            return isValid;
          });
      }, Promise.resolve());
  },

  required: input => input !== '' ? true : 'Required field',
};

const questions = [{
//   type: 'input',
//   name: 'instances',
//   message: 'How many instances of this config do you want?',
//   default: 1,
//   filter: input => Number(input),
//   validate: Validate.integer,
// }, {
//   type: 'input',
//   name: 'username',
//   message: 'Please enter the username',
//   validate: Validate.required,
// }, {
//   type: 'input',
//   name: 'hostname',
//   message: 'Please enter the hostname',
//   default: answers => answers.username,
// }, {
//   type: 'list',
//   name: 'useWifi',
//   message: 'Do you want to connect to WiFi?',
//   choices: [{
//     name: 'Yes',
//     value: true,
//   }, {
//     name: 'No',
//     value: false,
//   }],
// }, {
//   type: 'input',
//   name: 'wifiSSID',
//   message: 'WiFi SSID',
//   when: answers => answers.useWifi,
//   validate: Validate.required,
// }, {
//   type: 'password',
//   name: 'wifiPassword',
//   message: 'WiFi Password',
//   when: answers => answers.useWifi,
//   validate: Validate.required,
// }, {
  type: 'input',
  name: 'sshKey',
  message: 'Public SSH key path',
  filter: input => input.replace(/^~/, os.homedir()),
  validate: Validate.multi([
    Validate.required,
    Validate.isFile
  ])
}];

inquirer.prompt(questions)
  .then((answers) => {
    console.log({
      answers
    });
  });
