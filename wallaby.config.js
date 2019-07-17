console.log('new Date()', new Date());

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
     '**/*.coffee': wallaby.compilers.coffeeScript({}),
      '**/*.js': wallaby.compilers.babel()
    }
  };
};
