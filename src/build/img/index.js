/**
 * index
 *
 * This downloads and configures the Pi image
 */

/* Node modules */
const path = require('path');

/* Third-party modules */

/* Files */
const configureOS = require('./configureOS');
const download = require('./download');
const imgMounter = require('./imgMounter');

const config = {
  url: 'https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-04-19/2018-04-18-raspbian-stretch-lite.zip',
  sha256: 'https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-04-19/2018-04-18-raspbian-stretch-lite.zip.sha256',
  target: path.join(__dirname, '..', '..', '..', 'cache')
};

Promise.resolve()
  .then(() => download(config.url, config.target, config.sha256))
  // .then(() => `${config.target}/os.img`)
  .then(imgPath => imgMounter.mount(imgPath))
  .then(mountPoints => configureOS(config, mountPoints))
  .then(() => imgMounter.unmount())
  .catch((err) => {
    console.log(err.stack);
    process.exit(1);
  });
