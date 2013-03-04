util = require 'util'
rabbit = require './rabbit'
message = require './message'
database = require './database'
transport = require './transport'
config = require './local_config'

messenger = new rabbit.RabbitMessenger(
  config.connectionParams, config.queueName, config.exchangeName, config.pubExchangeName)

####################################################################################################
#                                                                                                  #
#                     Load tables from models and listen for local changes                         #
#                                                                                                  #
####################################################################################################
tables = {}
builders = {}

loadTable = (model) ->
  tables[model.tableName] = new database.Table(config.pool, model.tableName, model.keys, model.fields)

loadMessageBuilder= (model) ->
  builders[model.tableName] = new message.DataMessageBuilder(model.tableName, model.keys, model.fields)

startMonitor = (model) ->
  monitor = new database.TableMonitor(tables[model.tableName], 10000)
  monitor
    .on 'publish', (table, row) ->
      messenger.send builders[table.tableName].newPublishMessage(row)
      table.changeStatus(row, 5)
    .on 'update', (table, row) ->
      messenger.send builders[table.tableName].newUpdateMessage(row)
      table.changeStatus(row, 5)
    .on 'delete', (table, row) ->
      messenger.send builders[table.tableName].newDeleteMessage(row)
      table.delete(row)
    .start()

mediaTransport = new transport.MediaTransport('localhost:3000', 'localhost:3001')
startMediaMonitor = (model) ->
  monitor = new database.TableMonitor(tables[model.tableName], 10000)
  monitor
    .on 'publish', (table, row) ->
      mediaTransport.upload(row.uuid)
      table.changeStatus(row, 5)
    .on 'delete', (table, row) ->
      messenger.send builders[table.tableName].newDeleteMessage(row)
      table.delete(row)
    .start()

for model in require('./models').models
  loadTable(model)
  loadMessageBuilder(model)
  util.log 'Starting monitor: ' + model.tableName
  if model.tableName != 'media'
    startMonitor(model)
  else
    util.log 'Starting media monitor'
    startMediaMonitor(model)

####################################################################################################
#                                                                                                  #
#                                   Define handlers for actions                                    #
#                                                                                                  #
####################################################################################################
hostname = require('os').hostname()

onUpdate = (message) ->
  if message.source != hostname
    tables[message.type].update(message.id, message.content)
      .on 'updated', ->
        util.log('Updated: ' + message.type + JSON.stringify(message.id) + ' ' + JSON.stringify(message.content))
  else
    util.log('Ignored update message from self.')

onDelete = (message) ->
  if message.source != hostname
    tables[message.type].delete(message.id)
      .on 'deleted', ->
        util.log('Deleted: ' + message.type + JSON.stringify(message.id))
  else
    util.log('Ignored delete message from self.')


####################################################################################################
#                                                                                                  #
#                                Listen for updates from cloud                                     #
#                                                                                                  #
####################################################################################################
messenger.on 'message', (message) ->
  util.log('Received: ' + JSON.stringify(message))
  switch message.action
    when 'update'
      onUpdate(message)
    when 'delete'
      onDelete(message)
    else
      util.log('Unrecognized message: ' + JSON.stringify(message))

messenger.start()
