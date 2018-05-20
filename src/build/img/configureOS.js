/**
 * configureOS
 */

/* Node modules */
const path = require('path');

/* Third-party modules */
const { _ } = require('lodash');
const fs = require('fs-extra');

/* Files */
const logger = require('./logger');

function configToEnvvars (config) {
  const output = Object.keys(config)
    .map(key => {
      const value = config[key];

      const envKey = _
        .chain(key)
        .snakeCase()
        .toUpper()
        .value();

      return `export PI_${envKey}="${value}"`;
    });

  output.unshift('#!/usr/bin/env bash', '');
  output.push('');

  return output.join('\n');
}

module.exports = (config, { boot, root }) => {
  logger.info('Configuring OS');

  const envvarConfig = configToEnvvars(config);
  const dataDir = path.join(__dirname, '..', 'data');

  const piovenDir = 'pioven';

  const opts = {
    firstRun: {
      dest: path.join(root.dir, piovenDir),
      src: path.join(__dirname, '..', 'first-run')
    },
    hosts: {
      dest: path.join(root.dir, 'etc', 'hosts'),
      src: path.join(dataDir, 'hosts')
    },
    motd: {
      dest: path.join(root.dir, 'etc', 'profile.d', 'motd.sh'),
      existing: path.join(root.dir, 'etc', 'motd'),
      src: path.join(dataDir, 'motd.sh')
    },
    rcLocal: path.join(root.dir, 'etc', 'rc.local'),
    sshFile: path.join(boot.dir, 'ssh'),
    updater: {
      dest: path.join(root.dir, 'etc', 'cron.daily', 'update'),
      src: path.join(dataDir, 'update.sh'),
    },
    wpaConfFile: path.join(root.dir, 'etc', 'wpa_supplicant', 'wpa_supplicant.conf')
  };

  return Promise.resolve()
    /* Enable SSH */
    .then(() => {
      logger.info('Creating SSH file', {
        sshFile: opts.sshFile
      });

      return fs.ensureFile(opts.sshFile);
    })
    .then(() => {
      /* Set the WiFi data */
      if (!config.wifiSsid) {
        /* WiFi SSID not set - connect through ethernet */
        logger.info('WiFI SSID not set - wired internet only')
        return;
      }

      logger.info('Configuring WiFI', {
        ssid: config.wifiSsid,
        password: config.wifiPass,
      });

      return fs.readFile(opts.wpaConfFile, 'utf8')
        .then(contents => {
          if (/ssid=/.test(contents)) {
            /* Already inserted - don't insert again */
            return;
          }

          /* Append WiFi config to file */
          const wifi = [
            '',
            'network={',
            `  ssid="${config.wifiSsid}"`,
            `  psk="${config.wifiPass}"`,
            '}',
            ''
          ].join('\n');

          return fs.appendFile(opts.wpaConfFile, wifi)
            .then((result) => {
              logger.info('WiFi configured');
            });
        });
    })
    .then(() => {
      /* Copy the hosts file */
      return fs.copy(opts.hosts.src, opts.hosts.dest)
        .then(() => {
          logger.info(`Copied ${opts.hosts.src} to ${opts.hosts.dest}`);
        });
    })
    .then(() => {
      /* Set a daily crontab to update the OS */
      return fs.copy(opts.updater.src, opts.updater.dest)
        .then(() => fs.chmod(opts.updater.dest, '755'));
    })
    .then(() => {
      /* Set the Message of the Day generator */
      return fs.remove(opts.motd.existing)
        .then(() => fs.copy(opts.motd.src, opts.motd.dest))
        .then(() => fs.chmod(opts.motd.dest, '755'));
    })
    .then(() => {
      /* Copy the first run directory */
      return fs.copy(opts.firstRun.src, opts.firstRun.dest);
    })
    .then(() => {
      /* Copy the data required for first run */
      return Promise.all([
        fs.copy(config.sshKeyPub, path.join(opts.firstRun.dest, 'data', 'id_rsa.pub')),
        fs.writeFile(path.join(opts.firstRun.dest, 'config.sh'), envvarConfig, 'utf8'),
      ]);
    })
    .then(() => {
      /* Make the first run script run on boot */
      return fs.readFile(opts.rcLocal, 'utf8')
        .then(currentFile => {
          /* Remove the exit command */
          const firstRunFile = `/${piovenDir}/first_run.sh`;
          const re = new RegExp(firstRunFile);

          if (re.test(currentFile)) {
            /* Already in there - ignore */
            return;
          }

          let newFile = currentFile.split('\n')
            .map(line => line.replace('exit 0', ''))
            .join('\n');

          newFile += `if [ -f ${firstRunFile} ]; then
  printf 'Setting up the Pi'
  sh ${firstRunFile}
  printf 'Pi setup'
  
  reboot
fi

exit 0
`;

          return fs.writeFile(opts.rcLocal, newFile, 'utf8');
        });
    })
    .catch(err => {
      logger.error('OS configuration error', err);

      return Promise.reject(err);
    });
};
