/**
 * configureOS
 */

/* Node modules */
const path = require('path');

/* Third-party modules */
const fs = require('fs-extra');

/* Files */

module.exports = (config, { boot, root }) => {
  const dataDir = path.join(__dirname, '..', 'data');

  const opts = {
    firstRun: {
      dest: path.join(root.dir, 'pioven'),
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
    sshFile: path.join(boot.dir, 'ssh'),
    updater: {
      dest: path.join(root.dir, 'etc', 'cron.daily', 'update'),
      src: path.join(dataDir, 'update.sh'),
    },
    wpaConfFile: path.join(root.dir, 'etc', 'wpa_supplicant', 'wpa_supplicant.conf')
  };

  /* Enable SSH */
  return fs.ensureFile(opts.sshFile)
    .then(() => {
      /* Set the WiFi data */
      if (!config.wifiSsid) {
        /* WiFi SSID not set - connect through ethernet */
        return;
      }

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
        });
    })
    .then(() => {
      /* Copy the hosts file */
      return fs.copy(opts.hosts.src, opts.hosts.dest)
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
      /* Copy the first run data */
      return Promise.all([
        fs.copy(config.sshKeyPub, path.join(opts.firstRun.dest, 'data', 'id_rsa.pub'))
      ]);
    });
};
