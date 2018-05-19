/**
 * imgMounter
 */

/* Node modules */
const childProcess = require('child_process');
const path = require('path');
const util = require('util');

/* Third-party modules */
const { _ } = require('lodash');
const fs = require('fs-extra');

/* Files */
const logger = require('./logger');

const exec = (cmd, opts) => {
  logger.info('Execute Unix command', {
    cmd,
    opts
  });

  return util.promisify(childProcess.exec)(cmd, opts);
};

const config = {
  dirs: {
    boot: '/media/boot',
    root: '/media/root'
  },
  mounts: [{
    regex: /\w*p1\b/,
    type: 'boot'
  }, {
    regex: /\w*p2\b/,
    type: 'root'
  }]
};

function mountToDir ({ dir, point }) {
  const mountPoint = path.join(`${path.sep}dev`, 'mapper', point);
  return exec(`mount "${mountPoint}" ${dir}`)
    .then(() => ({
      dir,
      mountPoint
    }));
}

module.exports = {

  mount (osFile) {
    logger.info('Mounting new file', {
      osFile
    });

    return Promise.resolve()
      /* Ensure nothing still around from previous */
      .then(() => this.unmount(true))
      /* Create the directories that img will be mounted too */
      .then(() => Promise.all([
        fs.mkdirp(config.dirs.boot),
        fs.mkdirp(config.dirs.root),
      ]))
      /* Use kpartx to load the img file */
      .then(() => exec(`kpartx -vas ${osFile}`))
      .then(({ stdout }) => {
        /* Now extract the mount points for boot and root */
        const mountPoints = stdout.split('\n')
          .reduce((result, item) => {
            const { mounts } = config;

            mounts.forEach(({ regex, type }) => {
              if (regex.test(item)) {
                result.push({
                  point: item.match(regex)[0],
                  dir: config.dirs[type]
                });
              }
            });

            return result;
          }, []);

        if (mountPoints.length !== config.mounts.length) {
          throw new Error(`Not found boot and root in ${osFile}`);
        }

        return Promise.all(mountPoints.map(item => mountToDir(item)))
          .then(points => {
            /* This will probably come out in the correct order, but this guarantees it */
            return points.reduce((result, item) => {
              const inverted = _.invert(config.dirs);
              const type = inverted[item.dir];

              result[type] = item;

              return result;
            }, {});
          });
      })
      .then(result => new Promise(resolve => setTimeout(() => resolve(result), 5000)))
      .then(result => {
        logger.info('File mounted', {
          osFile
        });

        return result;
      })
      .catch(err => {
        logger.error('Mount error', err);

        return Promise.reject(err);
      });
  },

  unmount (ignoreError = false) {
    logger.info('Unmounting file', {
      ignoreError,
    });

    const dirs = Object.values(config.dirs);
    const tasks = dirs.map(dir => exec(`umount ${dir}`));

    return Promise.all(tasks)
      .then(() => undefined) /* This exists for consistency */
      .catch(err => {
        if (ignoreError === true) {
          /* Can ignore this error */
          return undefined;
        }

        return Promise.reject(err);
      })
      /* Remove logical volumes */
      .then(() => exec('dmsetup ls'))
      .then(({ stdout }) => {
        /* Remove logical volumes created */
        const tasks = stdout.split('\n')
          .reduce((result, line) => {
            config.mounts.forEach(mount => {
              if (mount.regex.test(line)) {
                const item = line.match(mount.regex);

                result.push(exec(`dmsetup remove ${item}`));
              }
            });

            return result;
          }, []);

        return Promise.all(tasks);
      })
      .then(result => {
        logger.info('Unmount successful');

        return result;
      })
      .catch(err => {
        logger.error('Unmount error', err);

        return Promise.reject(err);
      });
  }

};
