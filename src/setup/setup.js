/**
 * setup
 */

'use strict';

/* Node modules */
const path = require('path');

/* Third-party modules */
const fs = require('fs.extra');
const inquirer = require('inquirer');
const keyGen = require('ssh-keygen');

/* Files */
const questions = require('../config/index');

const keyDir = process.env.SSH_KEY_DIR || path.join(__dirname, '..', 'ssh-keys');
fs.mkdirpSync(keyDir);

inquirer.prompt(questions)
  .then((answers) => {
    /* Generate the SSH key */
    const location = path.join(keyDir, answers.PI_HOSTNAME);

    return new Promise((resolve, reject) => {
      keyGen({
        location,
        comment: answers.PI_HOSTNAME
      }, (err) => {
        if (err) {
          reject(err);
          return;
        }

        answers.PI_SSH_KEY = `${location}.pub`;

        resolve(answers);
      });
    });
  })
  .then((answers) => {
    const settings = [
      '#!/bin/sh',
      ''
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

    console.log('Setup completed successfully');
  })
  .catch((err) => {
    console.log('Setup errored');
    console.log(err.stack || err);
    process.exit(1);
  });
