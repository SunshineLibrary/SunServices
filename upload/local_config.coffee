mysql = require 'mysql'

exports.connectionParams = {
    host: '10.8.0.1'
    , login: 'local_server'
    , password: '8he90zhn3o'
    , vhost: '/sunshine'
}

exports.queueName = 'local.' + require('os').hostname()
exports.exchangeName = 'cloud.updates.broadcast'
exports.pubExchangeName = 'local.updates.publish'

exports.pool = mysql.createPool({
  host: 'localhost'
  , user     : 'local_server'
  , password : 'local_server'
  , database : 'local_server'
  , charset  : 'utf8'
})
