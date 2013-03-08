util = require 'util'
under = require 'underscore'

rabbit = require './rabbit'
database = require './database'
config= require './cloud_config'

messenger = new rabbit.RabbitMessenger(
  config.connectionParams, config.queueName, config.exchangeName, config.pubExchangeName)


#####################################################################################################
#                                                                                                   #
#       Load tables                                                                                 #
#                                                                                                   #
#####################################################################################################
tables = {}

for model in require('./models').models
  tables[model.tableName] = new database.Table(config.pool, model.tableName, model.keys, model.fields)


#####################################################################################################
#                                                                                                   #
#       Define handlers for actions                                                                 #
#                                                                                                   #
#####################################################################################################
onPublish = (message) ->
  if message.type = 'media'
    messenger.send message
  else
    tables[message.type].insert(message.id, message.content)
      .on 'inserted', ->
        util.log('Published: ' + message.type + JSON.stringify(message.id) + ' ' + JSON.stringify(message.content))

onUpdate = (message) ->
  tables[message.type].update(message.id, message.content)
    .on 'updated', ->
      util.log('Updated: ' + message.type + JSON.stringify(message.id) + ' ' + JSON.stringify(message.content))
      messenger.send message

onDelete = (message) ->
  tables[message.type].delete(message.id)
    .on 'deleted', ->
      util.log('Deleted: ' + message.type + JSON.stringify(message.id))
      messenger.send message


#####################################################################################################
#                                                                                                   #
#       Listen for updates from local servers                                                       #
#                                                                                                   #
#####################################################################################################
messenger.on 'message', (message) ->
  util.log('Received: ' + JSON.stringify(message))
  switch message.action
    when 'publish'
      onPublish(message)
    when 'update'
      onUpdate(message)
    when 'delete'
      onDelete(message)
    else
      console.log('Unrecognized message: ' + JSON.stringify(message))

messenger.start()
