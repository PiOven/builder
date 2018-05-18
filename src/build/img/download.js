/**
 * download
 */

/* Node modules */
const crypto = require('crypto');
const path = require('path');

/* Third-party modules */
const fs = require('fs-extra');
const glob = require('glob');
const ProgressBar = require('progress');
const request = require('request');
const unzip = require('unzip');

/* Files */

function discoverChecksum (url) {
  const supportedChecksums = [
    'sha1',
    'sha256',
    'md5'
  ];

  const ext = supportedChecksums.find(item => {
    const re = new RegExp(`.${item}`);

    return re.test(url);
  });

  if (!ext) {
    throw new Error(`Unsupported checksum: ${url}`);
  }

  return ext;
}

function download (url, target, filename, guessChecksum = false) {
  let filePath = path.join(target, filename);

  if (guessChecksum) {
    const ext = discoverChecksum(url);
    filePath += `.${ext}`;
  }

  const tmpPath = `${filePath}.tmp`;

  return fs.stat(filePath)
    .then(result => !result.isFile())
    .catch(() => true) /* Ignore - almost certainly because doesn't exist */
    .then(redownload => {
      if (!redownload) {
        return undefined
      }

      /* Need to redownload */
      return Promise.all([
        fs.remove(filePath),
        fs.remove(tmpPath)
      ]).then(() => new Promise((resolve, reject) => {
        const bar = new ProgressBar(` * Downloading ${filename}: :bar :percent :etas`, {
          complete: '#',
          incomplete: ' ',
          width: 72,
          total: 0
        });

        request
          .get(url)
          .on('data', (data) => {
            if (!bar.total) {
              /* No content length */
              return;
            }

            bar.tick(data.length, {});
          })
          .on('end', () => {
            resolve(filePath);
          })
          .on('error', (err) => {
            reject(err);
          })
          .on('response', (response) => {
            bar.total = response.headers['content-length'] || 0;
          })
          .pipe(fs.createWriteStream(tmpPath));
      })).then(() => fs.move(tmpPath, filePath));
    })
    .then(() => filePath);
}

function extractZip (compressedFile, outputDir) {
  return new Promise((resolve, reject) => {
    fs.createReadStream(compressedFile)
      .pipe(unzip.Extract({
        path: outputDir,
        verbose: true
      }))
      .on('close', () => {
        resolve(outputDir);
      })
      .on('error', (err) => {
        reject(err);
      });
  });
}

function verifyDownload (downloadPath, verifyPath) {
  return new Promise((resolve, reject) => {
    const algo = discoverChecksum(verifyPath);

    console.log(`Computing checksum with ${algo}`);

    const hash = crypto.createHash(algo);

    const input = fs.createReadStream(downloadPath);

    input.on('end', () => {
      resolve(hash.digest('hex'));
    }).on('error', (err) => {
      reject(err);
    }).on('readable', () => {
      const data = input.read();

      if (data) {
        hash.update(data);
      }
    });
  }).then(string => fs.readFile(verifyPath, 'utf8')
    .then(result => {
      const re = new RegExp(`${string}`);

      if (!re.test(result)) {
        /* Delete the files */
        return Promise.all([
          fs.remove(downloadPath),
          fs.remove(verifyPath)
        ]).then(() => Promise.reject(new Error('Checksum mismatch - try downloading again')));
      }

      console.log('Checksums matched!');

      return downloadPath;
    }));
}

module.exports = (url, target, checksum) => Promise.resolve()
  .then(() => {
    const tasks = [
      download(url, target, 'os.zip')
    ];

    /* Checksum is optional */
    if (checksum) {
      tasks.push(download(checksum, target, 'checksum', true));
    }

    return Promise.all(tasks)
      .then(([ osPath, checksumPath ]) => {
        if (!checksum) {
          console.warn('WARNING: No checksum given so download will not be verified');

          return osPath;
        }

        return verifyDownload(osPath, checksumPath);
      });
  })
  .then((filePath) => {
    /* Extract the file */
    const ext = path.extname(filePath);
    const outputDir = path.join(target, 'extracted');

    let extractor = null;

    if (ext === '.zip') {
      extractor = () => extractZip(filePath, outputDir);
    } else {
      throw new Error(`Unsupported file type: ${filePath}`);
    }

    return extractor();
  })
  .then(extractTarget => new Promise((resolve, reject) => {
    /* Locate the file */
    glob(`${extractTarget}/*.img`, (err, result) => {
      if (err) {
        reject(err);
        return;
      }

      if (result.length !== 1) {
        reject(new Error(`Cannot find img file: found ${result.length} match(es)`));
        return;
      }

      resolve(result[0]);
    });
  }))
  .then(imgfile => {
    /* Rename the target file */
    const outputFile = path.join(target, 'os.img');

    return fs.rename(imgfile, outputFile)
      .then(() => outputFile);
  });
