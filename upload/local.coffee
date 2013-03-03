rabbit = require './rabbit'
message = require './message'
mysql = require 'mysql'
database = require './database'

connectionParams = {
    host: '42.121.108.196'
    , login: 'local_server'
    , password: '8he90zhn3o'
    , vhost: '/sunshine'
}

queueName = 'local.' + require('os').hostname()
exchangeName = 'cloud.updates.broadcast'
pubExchangeName = 'local.updates.publish'

messenger = new rabbit.RabbitMessenger(connectionParams, queueName, exchangeName, pubExchangeName)
messenger.start()

builder = new message.DataMessageBuilder('pieces', 'uuid', ['name', 'description', 'piece_type', 'medium_id'])

pool  = mysql.createPool({
  host: 'localhost'
  , user     : 'local_server'
  , password : 'local_server'
  , database : 'local_server'
  , charset  : 'utf8'
})

table = new database.Table(pool, 'pieces', ['uuid', 'name', 'description', 'piece_type', 'medium_id'])
monitor = new database.TableMonitor(pool, table)
monitor
  .on 'publish', (row) ->
    messenger.send builder.newPublishMessage(row)
  .on 'update', (row) ->
    messenger.send builder.newUpdataeMessage(row)
  .on 'delete', (row) ->
    messenger.send builder.newDeleteMessage(row)
  .start()

