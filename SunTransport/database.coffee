util   = require 'util'
events = require 'events'
clc    = require 'cli-color'
init   = require './init.js'
under  = require 'underscore'

exports.STATUS = STATUS = {
  REQUEST_PUBLISH: 10
  , PUBLISHING: 11
  , REQUEST_UPDATE: 20
  , REQUEST_DELETE: 30
  , REQUEST_DOWNLOAD: 40
  , WAITING_DOWNLOAD: 41
  , DOWNLOADING: 42
  , DONE: 50
}

DEFAULT_CONDITION = {
  sync_status:
    [
      STATUS.REQUEST_PUBLISH
      , STATUS.REQUEST_UPDATE
      , STATUS.REQUEST_DELETE
      , STATUS.REQUEST_DOWNLOAD
    ]
}

exports.Table = new JS.Class({
  initialize: (pool, tableName, keys, fields) ->
    this.pool = pool
    this.keys = keys
    this.fields = fields
    this.allFields = under.union(keys, fields)
    this.tableName = tableName

  insert: (id, content) ->
    this.execute(this.getInsertStatement(id, content), 'inserted')

  query: (condition) ->
    condition = condition || DEFAULT_CONDITION
    this.execute(this.getSelectStatement(condition), 'row')

  update: (id, content) ->
    this.execute(this.getUpdateStatement(id, content), 'updated')

  delete: (id) ->
    this.execute(this.getDeleteStatement(id), 'deleted')

  changeStatus: (id, status) ->
    this.execute(this.getChangeStatusStatement(id, status), 'updated')

  changeAllStatus: (condition, status) ->
    this.execute(this.getChangeAllStatusStatement(condition, status), 'updated')

  execute: (statement, event) ->
    emitter = new events.EventEmitter()
    this.pool.getConnection (err, connection) ->
      connection.query(statement)
        .on 'error', (err) ->
          util.log(clc.red(err))
        .on 'result', (result) ->
          emitter.emit(event, result)
        .on 'end', ->
          connection.end()
          emitter.emit('end')
    return emitter

  getInsertStatement: (id, content) ->
    values = under.extend(under.clone(id), content)
    values = pickValues(values, this.allFields)
    'INSERT INTO ' + this.tableName +
      joinFields(this.allFields) + ' VALUES ' + joinFields(values)

  getSelectStatement: (condition) ->
    conditions = joinConditions(condition)
    'SELECT * FROM ' + this.tableName + ' WHERE ' + conditions

  getUpdateStatement: (id, content) ->
    conditions = joinConditions(under.pick(id, this.keys))
    values = joinKeyValues(under.pick(content, this.fields))
    'UPDATE ' + this.tableName + ' SET ' + values + ' WHERE ' + conditions

  getDeleteStatement: (id) ->
    conditions = joinConditions(under.pick(id, this.keys))
    'DELETE FROM ' + this.tableName + ' WHERE ' + conditions

  getChangeStatusStatement: (id, status) ->
    conditions = joinConditions(under.pick(id, this.keys))
    values = 'sync_status = ' + status
    'UPDATE ' + this.tableName + ' SET ' + values + ' WHERE ' + conditions
  getChangeAllStatusStatement: (condition, status) ->
    conditions = joinConditions(condition)
    values = 'sync_status = ' + status
    'UPDATE ' + this.tableName + ' SET ' + values + ' WHERE ' + conditions
})

exports.TableMonitor = new JS.Class(events.EventEmitter, {
  initialize: (table, interval=600000) ->
    this.table = table
    this.interval = interval

  start: ->
    this.pollData()

  pollData: ->
    self = this
    func = -> self.pollData()
    this.table.query()
      .on 'row', (row) ->
        self.processRow(row)
      .on 'end', ->
        setTimeout(func, self.interval)

  processRow: (row) ->
    for key, value of row
      if value instanceof Buffer
        row[key] = value.toString()

    if row.sync_status == STATUS.REQUEST_PUBLISH
      this.emit 'publish', this.table, row
    else if row.sync_status == STATUS.REQUEST_UPDATE
      this.emit 'update', this.table, row
    else if row.sync_status == STATUS.REQUEST_DELETE
      this.emit 'delete', this.table, row
    else if row.sync_status == STATUS.REQUEST_DOWNLOAD
      this.emit 'download', this.table, row
})

joinFields = (fields) ->
  '(' + join(fields) + ')'

joinKeyValues = (hash) ->
  join(k + ' = ' + escapeString(v) for k, v of hash)

joinConditions = (hash) ->
  join(getCondition(k, v) for k, v of hash, ' AND ')

join = (arr, separator=',') ->
  under.reduce(arr, (a,b) -> a + separator + b)

pickValues = (input, fields) ->
  (if typeof input[f] == 'string' then escapeString(input[f]) else input[f]) for f in fields

getCondition = (key, value) ->
  if value instanceof Array
    getArrayCondition(key, value)
  else
    getSingleCondition(key, value)

getArrayCondition = (key, value) ->
  key + ' IN (' + join(escapeString(v) for v in value) + ')'

getSingleCondition = (key, value) ->
  key + ' = ' + escapeString(value)

escapeString = (value) ->
  if under.isString(value) then '"' + value + '"' else escapeUndefined(value)

escapeUndefined = (value) ->
  if typeof value == 'undefined' then null else value
