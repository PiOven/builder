/**
 * saveZip
 */

/* Node modules */
const childProcess = require('child_process');
const path = require('path');
const util = require('util');

/* Third-party modules */
const fs = require('fs-extra');

/* Files */

const exec = util.promisify(childProcess.exec);

module.exports = (cacheDir, imgPath, config) => {
  const credentialsTarget = path.join(cacheDir, 'credentials.txt');
  const saveTarget = path.join(cacheDir, `${config.hostname}.zip`);
  const credentials = [
    `username: ${config.username}`,
    `password: ${config.password}`
  ].join('\n');

  return fs.writeFile(credentialsTarget, credentials)
    .then(() => {
      /* Does the fastest compression, with no internal directories */
      const cmd = `zip -1j ${saveTarget} ${credentialsTarget} ${imgPath}`;

      return exec(cmd);
    })
    .then(() => credentials);
};
