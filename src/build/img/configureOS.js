/**
 * configureOS
 */

/* Node modules */
const fs = require('fs');
const util = require('util');
const path = require('path');

/* Third-party modules */

/* Files */

module.exports = (config, { boot, root }) => Promise.resolve()
  .then(() => {
    /* Enable SSH */
    const sshFile = path.join(boot.dir, 'ssh');

    return util.promisify(fs.writeFile)(sshFile, '');
  });
