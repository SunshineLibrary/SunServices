util = require 'util'
under = require 'underscore'
message = require './message'
database = require './database'

HOSTNAME = require('os').hostname()
STATUS = require('./database').STATUS

module.exports = new JS.Class({
  initialize: (pool, models, messenger, transport) ->
    this.tables = {}
    this.builders = {}
    this.monitors = {}
    this.transport = transport
    this.messenger = messenger
    for model in models
      table = this.tables[model.tableName] = loadTable(pool, model)
      this.builders[model.tableName] = loadMessageBuilder(model)
      this.monitors[model.tableName] = loadMonitor(this, table)
    bindMessenger(messenger, this)
    this.downloadLock = {}
    this.mediaLock = {}
    this.mediaTable = this.tables['media']
    return this

  start: ->
    for tableName, monitor of this.monitors
      monitor.start()
    this.messenger.start()

  onRequestPublish: (table, row) ->
    self = this
    if table == this.mediaTable
      table.changeStatus(row, STATUS.PUBLISHING)
      this.transport.upload row.uuid, ->
        table.changeStatus(row, STATUS.DONE)
        self.send self.builders[table.tableName].newPublishMessage(row)
    else
      this.send this.builders[table.tableName].newPublishMessage(row)
      table.changeStatus(row, STATUS.DONE)

  onRequestUpdate: (table, row) ->
    this.send this.builders[table.tableName].newUpdateMessage(row)
    table.changeStatus(row, STATUS.DONE)

  onRequestDelete: (table, row) ->
    this.send this.builders[table.tableName].newDeleteMessage(row)
    table.delete(row)

  onRequestDownload: (table, row)->
    self = this
    table.changeStatus(row, STATUS.WAITING_DOWNLOAD)

    if row.medium_id?
      this.mediaExists row.medium_id, (exists) ->
        if !exists and acquireLock(self.mediaLock, row.medium_id)
          self.createMedia row.medium_id, ->
            releaseLock(self.mediaLock, row.medium_id)
          self.transport.checkDownload row.medium_id, ->
            if acquireLock(self.downloadLock, row.medium_id)
              self.startMediaDownload(row.medium_id)
    else if table.tableName == 'media'
      self.transport.checkDownload row.uuid, ->
        if acquireLock(self.downloadLock, row.uuid)
          self.startMediaDownload(row.uuid)

  onReceivePublish: (message) ->
    self = this
    if validateHost(message.source) and message.type == 'media'
      if acquireLock(this.downloadLock, message.id.uuid)
        findPendingDownload this.mediaTable, message.id, (row) ->
          self.startMediaDownload(row.uuid)

  onReceiveUpdate: (message) ->
    self = this
    if validateHost(message.source)
      this.tables[message.type].query(message.id)
        .on 'updated', (row) ->
          if message.medium_id != row.medium_id
            messsage.content['sync_status'] = STATUS.REQUEST_DOWNLOAD
          self.tables[message.type].update(message.id, message.content)
            .on 'updated', ->
              util.log('Updated: ' + message.type + JSON.stringify(message.id) + ' ' + JSON.stringify(message.content))

  onReceiveDelete: (message) ->
    if validateHost(message.source)
      this.tables[message.type].delete(message.id)
        .on 'deleted', ->
          util.log('Deleted: ' + message.type + JSON.stringify(message.id))

  mediaExists: (mediaId, callback) ->
    exists = false
    this.mediaTable.query({uuid: mediaId})
      .on 'result', ->
        exists = true
      .on 'end', ->
        callback(exists)

  createMedia: (mediaId, callback) ->
    self = this
    medium = {uuid: mediaId}
    this.mediaTable.insert(medium, {})
      .on 'end', ->
        self.mediaTable.changeStatus(medium, STATUS.WAITING_DOWNLOAD)
        callback()

  startMediaDownload: (mediaId) ->
    self = this
    medium = {uuid: mediaId}
    this.mediaTable.changeStatus(medium, STATUS.DOWNLOADING)
    this.transport.download mediaId, ->
      self.markDownloadComplete(mediaId)
      releaseLock(self.downloadLock, mediaId)

  markDownloadComplete: (mediaId) ->
    for tableName, table of this.tables
      if table == this.mediaTable
        table.changeStatus({uuid: mediaId}, STATUS.DONE)
      else if under.contains(table.fields, 'medium_id')
        table.changeAllStatus({medium_id: mediaId}, STATUS.DONE)

  send: (message) ->
    this.messenger.send message
})

loadTable = (pool, model) ->
   new database.Table(pool, model.tableName, model.keys, model.fields)

loadMessageBuilder = (model) ->
   new message.DataMessageBuilder(model.tableName, model.keys, model.fields)

loadMonitor = (handler, table_) ->
  monitor = new database.TableMonitor(table_, 10000)
  monitor
    .on 'publish', (table, row) ->
      handler.onRequestPublish(table, row)
    .on 'update', (table, row) ->
      handler.onRequestUpdate(table, row)
    .on 'delete', (table, row) ->
      handler.onRequestDelete(table, row)
    .on 'download', (table, row) ->
      handler.onRequestDownload(table, row)

bindMessenger = (messenger, handler) ->
  messenger.on 'message', (message) ->
    util.log('Received: ' + JSON.stringify(message))
    switch message.action
      when 'publish'
        handler.onReceivePublish(message)
      when 'update'
        handler.onReceiveUpdate(message)
      when 'delete'
        handler.onReceiveDelete(message)
      else
        util.log('Unrecognized message: ' + JSON.stringify(message))

validateHost = (hostname) ->
  isValid = (hostname != HOSTNAME)
  util.log('Ignored message from self.') unless isValid
  return isValid

acquireLock = (hash, key) ->
  if !hash[key] then hash[key] = true else false

releaseLock = (hash, key) ->
  delete hash[key]

PENDING_DOWNLOAD = {sync_status: [STATUS.REQUEST_DOWNLOAD, STATUS.WAITING_DOWNLOAD]}
findPendingDownload = (table, id, callback) ->
  conditions = under.extend(under.clone(PENDING_DOWNLOAD), id)
  table.query(conditions)
    .on 'row', (row) ->
      callback(row)
