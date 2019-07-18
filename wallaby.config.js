const _ = require('lodash');
const fs = require('fs');

ifExists = function(filename) {
  return fs.existsSync(filename) && filename;
};

module.exports = function (wallaby) {
  console.log('__dirname', __dirname);
  return {
    debug: true,

    files: _.compact([
      'lib/**/*.coffee',
      'babel.config.js',
      'jest.config.js',
      'jest-mongodb-config.js',
      ifExists('jest-mongodb-config.local.js')
    ]),

    tests: [
      'test/**/*.test.coffee'
    ],

    testFramework: 'jest',

    env: {
      type: 'node'
    },

    setup: function (wallaby) {
      var jestConfig = require('./jest.config');
      wallaby.testFramework.configure(jestConfig);
    },

    compilers: {
      // '**/*.coffee': wallaby.compilers.coffeeScript({}),
      // '**/*.js': wallaby.compilers.babel()
    }
  };
};
