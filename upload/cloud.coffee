util = require 'util'
rabbit = require './rabbit'
database = require './database'
config= require './cloud_config'
under = require 'underscore'

messenger = new rabbit.RabbitMessenger(
  config.connectionParams, config.queueName, config.exchangeName, config.pubExchangeName)

tables = {}

for model in require('./models').models
  tables[model.tableName] = new database.Table(config.pool, model.tableName, model.keys, model.fields)

messenger.on 'message', (message) ->
  util.log('Received: ' + JSON.stringify(message))
  switch message.action
    when 'publish'
      tables[message.type].insert(message.id, message.content)
        .on 'inserted', ->
          util.log('Published: ' + message.type + JSON.stringify(message.id) + ' ' + JSON.stringify(message.content))
    when 'update'
      tables[message.type].update(message.id, message.content)
        .on 'updated', ->
          util.log('Updated: ' + message.type + JSON.stringify(message.id) + ' ' + JSON.stringify(message.content))
          messenger.send message
    when 'delete'
      tables[message.type].delete(message.id)
        .on 'deleted', ->
          util.log('Deleted: ' + message.type + JSON.stringify(message.id))
          messenger.send message
    else
      console.log('Unrecognized message: ' + JSON.stringify(message))

messenger.start()
