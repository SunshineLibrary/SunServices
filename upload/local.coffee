util = require 'util'
rabbit = require './rabbit'
message = require './message'
database = require './database'
config = require './local_config'

messenger = new rabbit.RabbitMessenger(
  config.connectionParams, config.queueName, config.exchangeName, config.pubExchangeName)

tables = {}
builders = {}

for model in require('./models').models
  builders[model.tableName] = new message.DataMessageBuilder(model.tableName, model.keys, model.fields)
  tables[model.tableName] = new database.Table(config.pool, model.tableName, model.keys, model.fields)

  monitor = new database.TableMonitor(tables[model.tableName], 10000)
  monitor
    .on 'publish', (table, row) ->
      messenger.send builders[table.tableName].newPublishMessage(row)
      table.changeStatus(row, 4)
    .on 'update', (table, row) ->
      messenger.send builders[table.tableName].newUpdateMessage(row)
      table.changeStatus(row, 4)
    .on 'delete', (table, row) ->
      messenger.send builders[table.tableName].newDeleteMessage(row)
      table.delete(row)
    .start()

hostname = require('os').hostname()

messenger.on 'message', (message) ->
  util.log('Received: ' + JSON.stringify(message))
  switch message.action
    when 'update'
      if message.source != hostname
        tables[message.type].update(message.id, message.content)
          .on 'updated', ->
            util.log('Updated: ' + message.type + JSON.stringify(message.id) + ' ' + JSON.stringify(message.content))
      else
        util.log('Ignored update message from self.')
    when 'delete'
      if message.source != hostname
        tables[message.type].delete(message.id)
          .on 'deleted', ->
            util.log('Deleted: ' + message.type + JSON.stringify(message.id))
      else
        util.log('Ignored delete message from self.')
    else
      console.log('Unrecognized message: ' + JSON.stringify(message))

messenger.start()
