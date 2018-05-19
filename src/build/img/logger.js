/**
 * logger
 */

/* Node modules */

/* Third-party modules */
const winston = require('winston');

/* Files */

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.simple(),
  transports: [
    new winston.transports.Console()
  ]
});

module.exports = logger;
