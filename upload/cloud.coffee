rabbit = require './rabbit'
mysql = require 'mysql'
database = require './database'

connectionParams = {
  host: '42.121.108.196'
  , login: 'cloud_server'
  , password: 'gf84hvf893'
  , vhost: '/sunshine'
}

queueName = 'cloud.publisher'
exchangeName = 'local.updates.publish'
pubExchangeName = 'cloud.updates.broadcast'

pool  = mysql.createPool({
  host: 'localhost'
  , user     : 'cloud_server'
  , password : 'cloud_server'
  , database : 'cloud_server'
  , charset  : 'utf8'
})

messenger = new rabbit.RabbitMessenger(connectionParams, queueName, exchangeName, pubExchangeName)
table = new database.Table(pool, 'pieces', ['uuid', 'name', 'description', 'piece_type', 'medium_id'])

messenger.on 'message', (message) ->
  # console.log(key + " " + value) for key, value of message
  console.log JSON.stringify(message)
  console.log(message.id + message.content)
messenger.start()

