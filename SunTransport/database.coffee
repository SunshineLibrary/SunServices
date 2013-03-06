util   = require 'util'
events = require 'events'
clc    = require 'cli-color'
init   = require './init.js'
under  = require 'underscore'

exports.Table = new JS.Class({
  initialize: (pool, tableName, keys, fields) ->
    this.pool = pool
    this.keys = keys
    this.fields = fields
    this.allFields = under.union(keys, fields)
    this.tableName = tableName

  insert: (id, content) ->
    this.execute(this.getInsertStatement(id, content), 'inserted')

  query: ->
    this.execute(this.getSelectStatement(), 'row')

  update: (id, content) ->
    this.execute(this.getUpdateStatement(id, content), 'updated')

  delete: (id) ->
    this.execute(this.getDeleteStatement(id), 'deleted')

  changeStatus: (id, status) ->
    this.execute(this.getChangeStatusStatement(id, status), 'updated')

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

  getSelectStatement: ->
    'SELECT * FROM ' + this.tableName +
      ' WHERE sync_status = 1 OR sync_status = 2 OR sync_status = 3 OR sync_status = 4'

  getUpdateStatement: (id, content) ->
    conditions = joinConditionValues(under.pick(id, this.keys))
    values = joinKeyValues(under.pick(content, this.fields))
    'UPDATE ' + this.tableName + ' SET ' + values + ' WHERE ' + conditions

  getDeleteStatement: (id) ->
    conditions = joinConditionValues(under.pick(id, this.keys))
    'DELETE FROM ' + this.tableName + ' WHERE ' + conditions

  getChangeStatusStatement: (id, status) ->
    conditions = joinConditionValues(under.pick(id, this.keys))
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

    if row.sync_status == 1
      this.emit 'publish', this.table, row
    else if row.sync_status == 2
      this.emit 'update', this.table, row
    else if row.sync_status == 3
      this.emit 'delete', this.table, row
    else if row.sync_status == 4
      this.emit 'download', this.table, row
})

joinFields = (fields) ->
  '(' + join(fields) + ')'

joinKeyValues = (hash) ->
  join(k + ' = ' + escapeString(v) for k, v of hash)

joinConditionValues = (hash) ->
  join(k + ' = ' + escapeString(v) for k, v of hash, ' AND ')

join = (arr, separator=',') ->
  under.reduce(arr, (a,b) -> a + separator + b)

pickValues = (input, fields) ->
  (if typeof input[f] == 'string' then escapeString(input[f]) else input[f]) for f in fields

escapeString = (value) ->
  if under.isString(value) then '"' + value + '"' else escapeUndefined(value)

escapeUndefined = (value) ->
  if typeof value == 'undefined' then null else value
