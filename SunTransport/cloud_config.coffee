mysql = require 'mysql'

exports.connectionParams = {
  host: '10.8.0.1'
  , login: 'cloud_server'
  , password: 'gf84hvf893'
  , vhost: '/sunshine'
}

exports.queueName = 'cloud.publisher'
exports.exchangeName = 'local.updates.publish'
exports.pubExchangeName = 'cloud.updates.broadcast'

exports.pool  = mysql.createPool({
  host: 'localhost'
  , user     : 'cloud_server'
  , password : 'cloud_server'
  , database : 'cloud_server'
  , charset  : 'utf8'
})

