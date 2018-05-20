/**
 * saveZip
 */

/* Node modules */
const childProcess = require('child_process');
const path = require('path');
const util = require('util');

/* Third-party modules */
const fs = require('fs-extra');
const uuid = require('uuid');

/* Files */
const logger = require('./logger');

const exec = (cmd, opts) => {
  logger.info('Execute Unix command', {
    cmd,
    opts
  });

  return util.promisify(childProcess.exec)(cmd, opts);
};

module.exports = (imgPath, config) => {
  const id = uuid.v4();

  const credentialsTarget = path.join(config.cacheDir, `${config.hostname}-${id}.txt`);
  const saveTarget = path.join(config.cacheDir, `${config.hostname}-${id}.zip`);
  const credentials = [
    `Username: ${config.username}`,
    `Password: ${config.password}`
  ].join('\n');

  logger.info('Saving to ZIP file', {
    saveTarget
  });

  logger.info('Writing credentials to file', {
    credentialsTarget
  });

  return Promise.resolve()
    .then(() => fs.writeFile(credentialsTarget, credentials))
    .then(() => {
      /* Does the fastest compression, with no internal directories */
      const cmd = `zip -1j ${saveTarget} ${credentialsTarget} ${imgPath} ${config.sshKey} ${config.sshKeyPub}`;

      return exec(cmd);
    })
    .then(() => fs.remove(credentialsTarget))
    .then(() => {
      logger.info('ZIP saved successfully');

      return {
        credentials,
        saveTarget
      };
    })
    .catch(err => {
      logger.error('Error saving ZIP file', err);

      return Promise.reject(err);
    });
};
