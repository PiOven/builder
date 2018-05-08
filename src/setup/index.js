/**
 * index
 */

'use strict';

/* Node modules */
const path = require('path');

/* Third-party modules */
const fs = require('fs-extra');
const inquirer = require('inquirer');
const keyGen = require('ssh-keygen');

/* Files */
const questions = require('../config/index');

const keyDir = path.join(process.env.CACHE_DIR, 'ssh-keys');

Promise.resolve()
  .then(() => fs.mkdirp(keyDir))
  .then(() => {
    return inquirer.prompt(questions);
  })
  .then((answers) => {
    /* Generate the SSH key */
    const location = path.join(keyDir, answers.hostname);

    return new Promise((resolve, reject) => {
      keyGen({
        location,
        comment: answers.hostname
      }, (err) => {
        if (err) {
          console.log({
            err
          });
          reject(err);
          return;
        }

        answers.sshKey = `${location}.pub`;

        resolve(answers);
      });
    });
  })
  .then((answers) => {
    const settings = {};

    Object
      .keys(answers)
      .filter(key => /^_/.test(key) === false)
      .filter(key => answers[key] !== undefined)
      .forEach(key => {
        settings[key] = answers[key];
      });

    const filePath = path.join(process.env.CACHE_DIR, 'settings.json');

    return fs.writeFile(filePath, JSON.stringify(settings, null, 2), 'utf8');
  })
  .then(() => {
    console.log('Setup completed successfully');
  })
  .catch((err) => {
    console.log('Setup errored');
    console.log(err.stack || err);
    process.exit(1);
  });
