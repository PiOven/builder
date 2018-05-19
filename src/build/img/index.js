/**
 * index
 *
 * This downloads and configures the Pi image
 */

/* Node modules */
const path = require('path');

/* Third-party modules */
const randomString = require('randomstring');

/* Files */
const config = require('../../../cache/settings');
const configureOS = require('./configureOS');
const download = require('./download');
const logger = require('./logger');
const imgMounter = require('./imgMounter');
const saveZip = require('./saveZip');

config.cacheDir = path.join(__dirname, '..', '..', '..', 'cache');
config.password = randomString.generate({
  length: config.passwordLength,
  readable: true,
  charset: 'alphanumeric'
});

Promise.resolve()
  .then(() => download(config.osUrl, config.cacheDir, config.osVerify))
  .then(imgPath => imgMounter.mount(imgPath)
    .then(mountPoints => configureOS(config, mountPoints))
    .then(() => imgMounter.unmount())
    .then(() => saveZip(imgPath, config)))
  .then(({ credentials, saveTarget }) => {
    logger.info('Successfully configured', {
      credentials,
      saveTarget,
    });
  })
  .catch((err) => {
    logger.error('General error', err);
    process.exit(1);
  });
