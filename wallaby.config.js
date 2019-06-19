module.exports = function (wallaby) {
  return {
    files: [
      'lib/**/*.js'
    ],

    tests: [
      'test/**/*.test.js'
    ],

    testFramework: 'jest',

    env: {
      type: 'node'
    },

    compilers: {
      '**/*.js': wallaby.compilers.babel()
    }
  };
};
