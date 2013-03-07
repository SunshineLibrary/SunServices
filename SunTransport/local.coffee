#!/usr/bin/env coffee
util = require 'util'
rabbit = require './rabbit'
message = require './message'
database = require './database'
transport = require './transport'
config = require './local_config'

messenger = new rabbit.RabbitMessenger(
  config.connectionParams, config.queueName, config.exchangeName, config.pubExchangeName)


#####################################################################################################
#                                                                                                   #
#       Define handlers for local changes                                                           #
#                                                                                                   #
#####################################################################################################
tables = {}
builders = {}

loadTable = (model) ->
  tables[model.tableName] = new database.Table(config.pool, model.tableName, model.keys, model.fields)

loadMessageBuilder= (model) ->
  builders[model.tableName] = new message.DataMessageBuilder(model.tableName, model.keys, model.fields)

mediaTransport = new transport.MediaTransport('localhost', '10.8.0.2')

startMonitor = (model) ->
  monitor = new database.TableMonitor(tables[model.tableName], 10000)
  monitor
    .on 'publish', (table, row) ->
      messenger.send builders[table.tableName].newPublishMessage(row)
      table.changeStatus(row, 50)
    .on 'update', (table, row) ->
      messenger.send builders[table.tableName].newUpdateMessage(row)
      table.changeStatus(row, 50)
    .on 'delete', (table, row) ->
      messenger.send builders[table.tableName].newDeleteMessage(row)
      table.delete(row)
    .on 'download', (table, row) ->
      mediaTransport.download(row.medium_id)
      table.changeStatus(row, 50)
    .start()

startMediaMonitor = (model) ->
  monitor = new database.TableMonitor(tables[model.tableName], 10000)
  monitor
    .on 'publish', (table, row) ->
      mediaTransport.upload(row.uuid)
      table.changeStatus(row, database.STATUS.DONE)
    .on 'update', (table, row) ->
      mediaTransport.upload(row.uuid)
      table.changeStatus(row, database.STATUS.DONE)
    .on 'delete', (table, row) ->
      messenger.send builders[table.tableName].newDeleteMessage(row)
      table.delete(row)
    .start()


#####################################################################################################
#                                                                                                   #
#       Define handlers for actions                                                                 #
#                                                                                                   #
#####################################################################################################
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


#####################################################################################################
#                                                                                                   #
#       Load tables                                                                                 #
#                                                                                                   #
#####################################################################################################
for model in require('./models').models
  loadTable(model)
  loadMessageBuilder(model)
  if model.tableName != 'media'
    startMonitor(model)
  else
    startMediaMonitor(model)


#####################################################################################################
#                                                                                                   #
#       Start Listeners                                                                             #
#                                                                                                   #
#####################################################################################################
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
