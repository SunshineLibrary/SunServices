mysql = require 'mysql'

exports.connectionParams = {
  host: '10.8.0.1'
  , login: 'cloud_server'
  , password: ''
  , vhost: '/sunshine'
}

exports.queueName = 'cloud.publisher'
exports.exchangeName = 'local.updates.publish'
exports.pubExchangeName = 'cloud.updates.broadcast'

exports.pool  = mysql.createPool({
  host: 'localhost'
  , user     : 'cloud_server'
  , password : ''
  , database : 'cloud_server'
  , charset  : 'utf8'
})

