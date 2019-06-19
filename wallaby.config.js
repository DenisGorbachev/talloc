module.exports = function (wallaby) {
  return {
    files: [
      'lib/**/*.coffee'
    ],

    tests: [
      'test/**/*.test.coffee'
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
