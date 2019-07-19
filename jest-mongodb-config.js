fs = require('fs');
_ = require('lodash');

let localConfig = {};
const localConfigFilename = __dirname + '/jest-mongodb-config.local.js';
if (fs.existsSync(localConfigFilename)) {
  localConfig = require(localConfigFilename);
}

module.exports = _.merge({
  mongodbMemoryServerOptions: {
    instance: {
      dbName: 'jest'
    },
    binary: {
      skipMD5: true
    },
    autoStart: false,
    debug: false
  }
}, localConfig);
