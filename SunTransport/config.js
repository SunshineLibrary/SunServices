(function() {
  exports.connectionParams = {
    host: '10.8.0.1',
    login: 'warpgate',
    password: 'cf18ebb23a003',
    vhost: '/warpgate'
  };

  exports.hostname = require('os').hostname();

  exports.role = 'local';

}).call(this);
